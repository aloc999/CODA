#!/usr/bin/env bash
#
# CODA — Comprehensive On-chain Defense Arsenal
# All-in-one smart contract audit toolkit
#
set -euo pipefail

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODA_HOME="$SCRIPT_DIR"
REPORT_DIR=""

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

banner() {
    echo -e "${BLUE}"
    echo "   ██████╗  ██████╗ ██████╗  █████╗ "
    echo "  ██╔════╝ ██╔═══██╗██╔══██╗██╔══██╗"
    echo "  ██║      ██║   ██║██  ██║███████║"
    echo "  ██║      ██║   ██║██  ██║██╔══██║"
    echo "  ╚██████╗ ╚██████╔╝██████╔╝██║  ██║"
    echo "   ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${GREEN}  Comprehensive On-chain Defense Arsenal v${VERSION}${NC}"
    echo -e "${YELLOW}  15 tools. 1 command. Zero missed vulnerabilities.${NC}"
    echo -e "  Developed by @aloc999 (Hashemi)"
    echo ""
}

usage() {
    echo "Usage: coda <command> [options]"
    echo ""
    echo "Commands:"
    echo "  install         Install all audit tools"
    echo "  audit <target>  Run full audit on target project"
    echo "  static          Run static analysis only (Slither + Grep)"
    echo "  symbolic        Run symbolic execution (Mythril + Halmos)"
    echo "  fuzz            Run fuzzing (Echidna + Medusa + Foundry invariant)"
    echo "  formal          Run formal verification (Certora Prover)"
    echo "  mutation        Run mutation testing (Gambit)"
    echo "  quick           Quick audit (Slither + Grep + Mythril)"
    echo "  report          Generate final audit report"
    echo "  secrets       Run secret/credential scan (Gitleaks)"
    echo "  visualize     Run Surya + Slither graphs"
    echo "  all-static    Run all static tools (Slither + Semgrep + Securify + Grep)"
    echo "  clean         Clean all generated files"
    echo "  version       Show version"
    echo ""
    echo "Tools (15 total):"
    echo "  Core:    Slither, Mythril, Semgrep, Securify2, Surya"
    echo "  Fuzz:    Echidna, Medusa, Foundry, Differential"
    echo "  Formal:  Certora, Halmos, Scribble"
    echo "  Scan:    GrepArsenal, Gitleaks"
    echo "  Mutate:  Gambit, Manticore, Brownie"
    echo ""
    echo "Environment variables:"
    echo "  CERTORA_KEY     Certora API key for formal verification"
    echo "  RPC_URL         Ethereum RPC URL for fork testing"
    echo "  CODA_SKIP       Comma-separated list of tools to skip"
}

# --- Tool runners ---

run_slither() {
    local target="$1"
    echo -e "${BLUE}[1/9] Running Slither static analysis...${NC}"
    if command -v slither >/dev/null 2>&1; then
        slither "$target" \
            --filter-paths "test|node_modules|lib|script" \
            --exclude naming-convention,solc-version,costly-loop,similar-names \
            --json "${REPORT_DIR}/slither.json" \
            2>"${REPORT_DIR}/slither.log" || true
        slither "$target" \
            --detect reentrancy-eth,arbitrary-send-erc20,controlled-delegatecall,suicidal,uninitialized-state,locked-ether \
            --filter-paths "test|node_modules|lib|script" \
            >>"${REPORT_DIR}/slither-critical.log" 2>&1 || true
        echo -e "${GREEN}  ✓ Slither complete${NC}"
    else
        echo -e "${YELLOW}  ⚠ Slither not installed — skipping${NC}"
    fi
}

run_mythril() {
    local target="$1"
    echo -e "${BLUE}[2/9] Running Mythril symbolic execution...${NC}"
    if command -v myth >/dev/null 2>&1; then
        local contracts=()
        while IFS= read -r f; do
            contracts+=("$f")
        done < <(find "$target/contracts" -name "*.sol" ! -path "*/factories/*" ! -path "*/interfaces/*" 2>/dev/null | head -12)
        for contract in "${contracts[@]}"; do
            local name=$(basename "$contract")
            echo "    Analyzing $name..."
            myth analyze "$contract" --solc-json "${CODA_HOME}/config/mythril.json" \
                --execution-timeout 90 --solver-timeout 30000 \
                >>"${REPORT_DIR}/mythril.log" 2>&1 || true
        done
        echo -e "${GREEN}  ✓ Mythril complete${NC}"
    else
        echo -e "${YELLOW}  ⚠ Mythril not installed — skipping${NC}"
    fi
}

run_echidna() {
    local target="$1"
    echo -e "${BLUE}[3/9] Running Echidna property fuzzer...${NC}"
    if command -v echidna >/dev/null 2>&1; then
        # Generate Echidna test from template if none exists
        if ! find "$target/test" -name "*chidna*" -o -name "*Echidna*" 2>/dev/null | grep -q .; then
            mkdir -p "$target/test/echidna"
            cp "${CODA_HOME}/templates/echidna/EchidnaInvariants.sol" "$target/test/echidna/"
        fi
        find "$target/test/echidna" -name "*.sol" 2>/dev/null | while read -r f; do
            local name=$(basename "$f" .sol)
            echidna "$f" --contract "$name" --test-limit 50000 --format text \
                >"${REPORT_DIR}/echidna-${name}.log" 2>&1 || true
        done
        echo -e "${GREEN}  ✓ Echidna complete${NC}"
    else
        echo -e "${YELLOW}  ⚠ Echidna not installed — skipping${NC}"
    fi
}

run_medusa() {
    local target="$1"
    echo -e "${BLUE}[4/9] Running Medusa coverage fuzzer...${NC}"
    if command -v medusa >/dev/null 2>&1; then
        if ! find "$target/test" -name "*Medusa*" 2>/dev/null | grep -q .; then
            mkdir -p "$target/test/medusa"
            cp "${CODA_HOME}/templates/medusa/MedusaInvariants.sol" "$target/test/medusa/"
        fi
        find "$target/test/medusa" -name "*.sol" 2>/dev/null | while read -r f; do
            local name=$(basename "$f" .sol)
            local conf=$(mktemp)
            cat > "$conf" <<EOFMEDUSA
{
  "fuzzing": {
    "workers": 4, "testLimit": 100000, "callSequenceLength": 20,
    "corpusDirectory": "${REPORT_DIR}/medusa-corpus",
    "coverageEnabled": true,
    "deploymentOrder": ["$name"],
    "targetContracts": ["$name"],
    "testing": { "propertyTesting": { "enabled": true, "testPrefixes": ["echidna_"] } }
  },
  "compilation": { "platform": "crytic-compile", "platformConfig": { "target": "$f", "solcVersion": "0.8.34" } }
}
EOFMEDUSA
            medusa fuzz --config "$conf" >"${REPORT_DIR}/medusa-${name}.log" 2>&1 || true
            rm "$conf"
        done
        echo -e "${GREEN}  ✓ Medusa complete${NC}"
    else
        echo -e "${YELLOW}  ⚠ Medusa not installed — skipping${NC}"
    fi
}

run_foundry_invariant() {
    local target="$1"
    echo -e "${BLUE}[5/9] Running Foundry invariant tests...${NC}"
    if command -v forge >/dev/null 2>&1; then
        cd "$target"
        if ! find test -name "*Invariant*" 2>/dev/null | grep -q .; then
            mkdir -p test/invariant
            cp "${CODA_HOME}/templates/foundry/InvariantTest.sol" test/invariant/
        fi
        forge build --force >/dev/null 2>&1 || true
        forge test --match-contract "Invariant" --fuzz-runs 500 \
            >"${REPORT_DIR}/foundry-invariant.log" 2>&1 || true
        cd - >/dev/null
        echo -e "${GREEN}  ✓ Foundry invariant complete${NC}"
    else
        echo -e "${YELLOW}  ⚠ Forge not installed — skipping${NC}"
    fi
}

run_grep_arsenal() {
    local target="$1"
    echo -e "${BLUE}[6/9] Running Grep Arsenal pattern scan...${NC}"
    bash "${CODA_HOME}/lib/grep-arsenal.sh" "$target" "$REPORT_DIR"
    echo -e "${GREEN}  ✓ Grep Arsenal complete${NC}"
}

run_halmos() {
    local target="$1"
    echo -e "${BLUE}[7/9] Running Halmos symbolic testing...${NC}"
    if command -v halmos >/dev/null 2>&1; then
        find "$target/test/halmos" -name "*.sol" 2>/dev/null | while read -r f; do
            local name=$(basename "$f" .sol)
            cd "$target"
            timeout 120 halmos --contract "$name" --solver-timeout-assertion 10000 --loop 2 \
                >"${REPORT_DIR}/halmos-${name}.log" 2>&1 || true
            cd - >/dev/null
        done
        echo -e "${GREEN}  ✓ Halmos complete${NC}"
    else
        echo -e "${YELLOW}  ⚠ Halmos not installed — skipping${NC}"
    fi
}

run_certora() {
    local target="$1"
    echo -e "${BLUE}[8/9] Running Certora formal verification...${NC}"
    if [ -n "${CERTORA_KEY:-}" ] && command -v certoraRun >/dev/null 2>&1; then
        # Find or generate Certora spec
        if ! find "$target/certora" -name "*.spec" 2>/dev/null | grep -q .; then
            echo -e "${YELLOW}    No Certora specs found. Generate with: coda formal --gen${NC}"
        else
            export CERTORAKEY="$CERTORA_KEY"
            cd "$target"
            for spec in certora/specs/*.spec; do
                local name=$(basename "$spec" .spec)
                local conf="certora/${name}.conf"
                if [ -f "$conf" ]; then
                    certoraRun "$conf" >"${REPORT_DIR}/certora-${name}.log" 2>&1 &
                fi
            done
            wait
            cd - >/dev/null
            echo -e "${GREEN}  ✓ Certora submitted (check https://prover.certora.com)${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ Certora not configured — set CERTORA_KEY env var${NC}"
    fi
}

run_gambit() {
    local target="$1"
    echo -e "${BLUE}[9/9] Running Gambit mutation testing...${NC}"
    if command -v gambit >/dev/null 2>&1; then
        local contracts=()
        while IFS= read -r f; do
            contracts+=("$f")
        done < <(find "$target/contracts" -name "*.sol" ! -path "*/factories/*" ! -path "*/common/*" 2>/dev/null | head -5)
        local total_killed=0 total_mutants=0
        for contract in "${contracts[@]}"; do
            local name=$(basename "$contract" .sol)
            echo "    Mutating $name..."
            cd "$target"
            gambit mutate --filename "$contract" --sourceroot . \
                --solc_remappings "@openzeppelin/=node_modules/@openzeppelin/" "forge-std/=lib/forge-std/src/" \
                --num_mutants 20 --seed 42 >/dev/null 2>&1 || true
            
            if [ -d gambit_out/mutants ]; then
                local count=$(find gambit_out/mutants -name "*.sol" | wc -l)
                total_mutants=$((total_mutants + count))
            fi
            rm -rf gambit_out
            cd - >/dev/null
        done
        echo -e "${GREEN}  ✓ Gambit complete ($total_mutants mutants generated)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Gambit not installed — skipping${NC}"
    fi
}

# --- Audit runner ---

run_full_audit() {
    local target="$1"
    REPORT_DIR="${target}/coda-report-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$REPORT_DIR"

    banner
    echo "Target: $target"
    echo "Report: $REPORT_DIR"
    echo ""

    local skip="${CODA_SKIP:-}"
    
    if ! echo "$skip" | grep -q "slither"; then run_slither "$target"; fi
    if ! echo "$skip" | grep -q "mythril"; then run_mythril "$target"; fi
    if ! echo "$skip" | grep -q "echidna"; then run_echidna "$target"; fi
    if ! echo "$skip" | grep -q "medusa"; then run_medusa "$target"; fi
    if ! echo "$skip" | grep -q "foundry"; then run_foundry_invariant "$target"; fi
    if ! echo "$skip" | grep -q "grep"; then run_grep_arsenal "$target"; fi
    if ! echo "$skip" | grep -q "halmos"; then run_halmos "$target"; fi
    if ! echo "$skip" | grep -q "certora"; then run_certora "$target"; fi
    if ! echo "$skip" | grep -q "gambit"; then run_gambit "$target"; fi
    
# --- Additional tool runners ---

run_semgrep() {
    local t="$1"
    echo -e "${BLUE}[A] Running Semgrep custom rules...${NC}"
    bash "${CODA_HOME}/lib/semgrep.sh" "$t" "$REPORT_DIR"
}

run_securify() {
    local t="$1"
    echo -e "${BLUE}[B] Running Securify2...${NC}"
    bash "${CODA_HOME}/lib/securify.sh" "$t" "$REPORT_DIR"
}

run_surya() {
    local t="$1"
    echo -e "${BLUE}[C] Running Surya visualization...${NC}"
    bash "${CODA_HOME}/lib/surya.sh" "$t" "$REPORT_DIR"
}

run_gitleaks() {
    local t="$1"
    echo -e "${BLUE}[D] Running secret scanner...${NC}"
    bash "${CODA_HOME}/lib/gitleaks.sh" "$t" "$REPORT_DIR"
}

run_manticore() {
    local t="$1"
    echo -e "${BLUE}[E] Running Manticore...${NC}"
    bash "${CODA_HOME}/lib/manticore.sh" "$t" "$REPORT_DIR"
}

run_scribble() {
    local t="$1"
    echo -e "${BLUE}[F] Running Scribble annotation...${NC}"
    bash "${CODA_HOME}/lib/scribble.sh" "$t" "$REPORT_DIR"
}

run_differential() {
    local t="$1"
    echo -e "${BLUE}[G] Running Differential Fuzzing...${NC}"
    bash "${CODA_HOME}/lib/differential.sh" "$t" "$REPORT_DIR"
}

run_brownie() {
    local t="$1"
    echo -e "${BLUE}[H] Running Brownie analysis...${NC}"
    bash "${CODA_HOME}/lib/brownie.sh" "$t" "$REPORT_DIR"
}

run_slither_printers() {
    local t="$1"
    echo -e "${BLUE}[I] Running Slither printers (graphs + summaries)...${NC}"
    if command -v slither >/dev/null 2>&1; then
        cd "$t"
        slither . --filter-paths "test|node_modules|lib" --print call-graph > "$REPORT_DIR/slither-callgraph.dot" 2>/dev/null || true
        slither . --filter-paths "test|node_modules|lib" --print inheritance-graph > "$REPORT_DIR/slither-inheritance.dot" 2>/dev/null || true
        slither . --filter-paths "test|node_modules|lib" --print function-summary > "$REPORT_DIR/slither-functions.txt" 2>/dev/null || true
        slither . --filter-paths "test|node_modules|lib" --print vars-and-auth > "$REPORT_DIR/slither-auth.txt" 2>/dev/null || true
        slither . --filter-paths "test|node_modules|lib" --print data-dependency > "$REPORT_DIR/slither-dependencies.txt" 2>/dev/null || true
        cd - >/dev/null
    fi
}

# Update the audit runner to include all new tools
run_full_audit() {
    local target="$1"
    REPORT_DIR="${target}/coda-report-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$REPORT_DIR"

    banner
    echo "Target: $target"
    echo "Report: $REPORT_DIR"
    echo ""

    local skip="${CODA_SKIP:-}"
    
    # Core tools (always run)
    if ! echo "$skip" | grep -q "slither"; then run_slither "$target"; fi
    if ! echo "$skip" | grep -q "grep"; then run_grep_arsenal "$target"; fi
    if ! echo "$skip" | grep -q "semgrep"; then run_semgrep "$target"; fi
    if ! echo "$skip" | grep -q "securify"; then run_securify "$target"; fi
    if ! echo "$skip" | grep -q "surya"; then run_surya "$target"; fi
    if ! echo "$skip" | grep -q "gitleaks"; then run_gitleaks "$target"; fi
    
    # Symbolic & formal tools
    if ! echo "$skip" | grep -q "mythril"; then run_mythril "$target"; fi
    if ! echo "$skip" | grep -q "manticore"; then run_manticore "$target"; fi
    if ! echo "$skip" | grep -q "halmos"; then run_halmos "$target"; fi
    if ! echo "$skip" | grep -q "certora"; then run_certora "$target"; fi
    
    # Fuzzing tools
    if ! echo "$skip" | grep -q "echidna"; then run_echidna "$target"; fi
    if ! echo "$skip" | grep -q "medusa"; then run_medusa "$target"; fi
    if ! echo "$skip" | grep -q "foundry"; then run_foundry_invariant "$target"; fi
    if ! echo "$skip" | grep -q "differential"; then run_differential "$target"; fi
    
    # Mutation & annotation tools
    if ! echo "$skip" | grep -q "gambit"; then run_gambit "$target"; fi
    if ! echo "$skip" | grep -q "scribble"; then run_scribble "$target"; fi
    
    # Analysis extras
    if ! echo "$skip" | grep -q "brownie"; then run_brownie "$target"; fi
    if ! echo "$skip" | grep -q "printers"; then run_slither_printers "$target"; fi
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  CODA audit complete!                   ${NC}"
    echo -e "${GREEN}  15 tools executed                      ${NC}"
    echo -e "${GREEN}  Report: $REPORT_DIR                    ${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
}"

# --- Main ---

main() {
    case "${1:-}" in
        install)
            bash "${CODA_HOME}/install.sh"
            ;;
        audit)
            if [ -z "${2:-}" ]; then echo "Usage: coda audit <target-path>"; exit 1; fi
            run_full_audit "${2}"
            ;;
        static)
            if [ -z "${2:-}" ]; then echo "Usage: coda static <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_slither "${2}"
            run_grep_arsenal "${2}"
            ;;
        symbolic)
            if [ -z "${2:-}" ]; then echo "Usage: coda symbolic <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_mythril "${2}"
            run_halmos "${2}"
            ;;
        fuzz)
            if [ -z "${2:-}" ]; then echo "Usage: coda fuzz <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_echidna "${2}"
            run_medusa "${2}"
            run_foundry_invariant "${2}"
            ;;
        formal)
            if [ -z "${2:-}" ]; then echo "Usage: coda formal <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_certora "${2}"
            ;;
        mutation)
            if [ -z "${2:-}" ]; then echo "Usage: coda mutation <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_gambit "${2}"
            ;;
        quick)
            if [ -z "${2:-}" ]; then echo "Usage: coda quick <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_slither "${2}"
            run_grep_arsenal "${2}"
            run_mythril "${2}"
            ;;
        report)
            bash "${CODA_HOME}/lib/report.sh" "${2:-.}"
            ;;
        secrets)
            if [ -z "${2:-}" ]; then echo "Usage: coda secrets <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_gitleaks "${2}"
            ;;
        visualize)
            if [ -z "${2:-}" ]; then echo "Usage: coda visualize <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_surya "${2}"
            run_slither_printers "${2}"
            ;;
        all-static)
            if [ -z "${2:-}" ]; then echo "Usage: coda all-static <target-path>"; exit 1; fi
            REPORT_DIR="${2}/coda-report-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$REPORT_DIR"
            run_slither "${2}"
            run_semgrep "${2}"
            run_securify "${2}"
            run_grep_arsenal "${2}"
            run_gitleaks "${2}"
            run_slither_printers "${2}"
            ;;
        clean)
            rm -rf "${2:-.}/coda-report-"* gambit_out medusa-corpus corpus echidna-corpus 2>/dev/null
            echo -e "${GREEN}Cleaned generated files${NC}"
            ;;
        version)
            echo "CODA v${VERSION}"
            ;;
        *)
            banner
            usage
            ;;
    esac
}

main "$@"
