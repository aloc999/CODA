#!/usr/bin/env bash
# CODA Securify2 — Ethereum Foundation formal static analyzer
# Proves properties like "no locked ether", "no unchecked sends"
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-securify}"

echo "[Securify2] Setting up..."
mkdir -p "$REPORT"

if ! command -v securify >/dev/null 2>&1; then
    # Try installing from source or binary
    pip3 install securify2 2>/dev/null || {
        # Docker-based as fallback
        if command -v docker >/dev/null 2>&1; then
            echo "[Securify2] Using Docker..."
            find "$TARGET" -name "*.sol" -path "*/contracts/*" ! -path "*/factories/*" 2>/dev/null | head -10 | while read -r f; do
                local name=$(basename "$f")
                docker run --rm -v "$(pwd):/src" securify2/securify2 "/src/$f" 2>/dev/null > "$REPORT/${name}.securify.txt" || true
            done
        else
            echo "  ⚠ Securify2 not available — install Docker or: pip3 install securify2"
            echo "  Manual install: https://github.com/eth-sri/securify2"
            exit 0
        fi
    }
fi

# Run Securify2 on each contract
echo "[Securify2] Analyzing contracts..."
find "$TARGET/contracts" -name "*.sol" ! -path "*/factories/*" ! -path "*/interfaces/*" 2>/dev/null | head -10 | while read -r f; do
    name=$(basename "$f" .sol)
    echo "  $name..."
    securify "$f" --include-contracts "$name" --output json > "$REPORT/${name}.json" 2>/dev/null || true
    securify "$f" --include-contracts "$name" > "$REPORT/${name}.txt" 2>/dev/null || true
done

# Summarize findings
echo "[Securify2] Generating summary..."
cat > "$REPORT/summary.txt" << 'SECURITY'
Securify2 Property Checks:
- TOD_transfer (No Ether Left)
- DAO (Reentrancy)
- SE (Unrestricted Selfdestruct)
- TX_origin (tx.origin Authentication)
- LE (Locked Ether)
- IO (Integer Overflow)
- UC (Unchecked Calls)
- ME (Missing Events)

Severity scale: Violation / Warning / Safe
SECURITY

find "$REPORT" -name "*.txt" ! -name "summary.txt" -exec grep -l "Violation\|Warning" {} \; 2>/dev/null >> "$REPORT/summary.txt" || true

echo "[Securify2] Done. Reports in $REPORT"
