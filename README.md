# CODA — Comprehensive On-chain Defense Arsenal

**15 tools. 1 command. Zero missed vulnerabilities.**

Developed by [@aloc999](https://github.com/aloc999) (Hashemi)

CODA is the most comprehensive smart contract audit toolkit in existence. 15 security tools integrated into a single, unified workflow — from static analysis to formal verification to mutation testing.

## Tools Included

| # | Tool | Type | What It Catches |
|---|------|------|----------------|
| 1 | **Slither** | Static Analysis (91 detectors) | Reentrancy, access control, uninitialized state |
| 2 | **Slither Printers** | Visualization | Call graphs, inheritance, auth maps, data flows |
| 3 | **Semgrep** | Custom Rules (13 detectors) | Solidity-specific patterns, silent modifiers, proxy bugs |
| 4 | **Securify2** | Formal Static Analysis | Proves: locked ether, unchecked sends, reentrancy |
| 5 | **Mythril** | Symbolic Execution | Integer overflow, unprotected selfdestruct, reachability |
| 6 | **Manticore** | Symbolic Execution (ToB) | EVM-level bugs, multi-transaction symbolic paths |
| 7 | **Halmos** | Symbolic Proving | Prove properties for ALL inputs (Z3/yices SMT) |
| 8 | **Echidna** | Property Fuzzing | Invariant violations via 50K+ random call sequences |
| 9 | **Medusa** | Coverage-Guided Fuzzing | Deep state exploration, multi-core |
| 10 | **Foundry** | Invariant Testing | Stateful fuzzing with real contract state |
| 11 | **Differential Fuzzing** | Comparative Testing | Catch discrepancies between equivalent functions |
| 12 | **Grep Arsenal** | Pattern Scan | 50+ vulnerability patterns (oracle, proxy, sig replay) |
| 13 | **Gitleaks** | Secret Scanning | Private keys, API tokens, mnemonics, passwords |
| 14 | **Certora Prover** | Formal Verification | Cloud-based formal verification |
| 15 | **Gambit** | Mutation Testing | Verify test suite comprehensive coverage |
| + | **Scribble** | Annotation | Runtime property checking from source annotations |
| + | **Brownie** | Test Framework | Python-based integration testing |
| + | **Surya** | Visualization | Inheritance graphs, dependency maps |
| + | **CI/CD** | Automation | GitHub Actions: audit on every push/PR |

## Quick Start

```bash
# 1. Clone and install
git clone https://github.com/aloc999/coda.git
cd coda
bash install.sh

# 2. Add to PATH
echo 'export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 3. Run a full audit
coda audit /path/to/project      # FULL audit (all 15 tools)
coda quick /path/to/project        # Fast audit (Slither + Grep + Mythril)
coda all-static /path/to/project   # All static: Slither + Semgrep + Securify + Grep + Gitleaks
coda fuzz /path/to/project         # All fuzzing: Echidna + Medusa + Foundry + Differential
coda symbolic /path/to/project     # All symbolic: Mythril + Manticore + Halmos
coda secrets /path/to/project      # Secret scan: Gitleaks
coda visualize /path/to/project    # Graphs: Surya + Slither printers
coda formal /path/to/project       # Formal verification: Certora Prover
coda mutation /path/to/project     # Mutation testing: Gambit
coda report /path/to/project       # Generate audit report
```

## Configuration

Copy `config/coda.conf` to your project and customize:

```bash
cp config/coda.conf /path/to/your/project/.coda.conf
```

Key environment variables:

```bash
export CERTORA_KEY="your_certora_api_key"  # For formal verification
export RPC_URL="https://eth-mainnet.g.alchemy.com/v2/..."  # For fork testing
export CODA_SKIP="certora,gambit"  # Skip specific tools
```

## Templates

CODA includes ready-to-use test templates for:

- `templates/echidna/EchidnaInvariants.sol` — Property-based fuzzing
- `templates/medusa/MedusaInvariants.sol` — Coverage-guided fuzzing
- `templates/certora/Invariants.spec` — Formal verification rules
- `templates/foundry/InvariantTest.sol` — Foundry invariant tests
- `templates/halmos/HalmosSymTest.sol` — Symbolic tests

Drop these into your project, customize the invariants, and run the audit.

## Typical Audit Flow

```
Quick audit (Slither + Grep + Mythril + Semgrep)  ~4 min    →  First pass
All-static (Slither + Semgrep + Securify + Grep)   ~6 min    →  Static sweep
Symbolic (Mythril + Manticore + Halmos)            ~15 min   →  Prove all paths
Fuzzing (Echidna + Medusa + Foundry + Diff)        ~20 min   →  Break invariants
Formal verification (Certora)                      ~10 min   →  Cloud formal proof
Mutation testing (Gambit)                          ~15 min   →  Test suite coverage
Secrets + Visualize                                ~3 min    →  Keys, graphs, deps
─────────────────────────────────────────────────────────────
FULL AUDIT (all 15 tools)                          ~70 min   →  Complete coverage
```

## Example Output

```
$ coda audit ./my-defi-protocol

   ██████╗  ██████╗ ██████╗  █████╗
  ██╔════╝ ██╔═══██╗██╔══██╗██╔══██╗
  ██║      ██║   ██║██║  ██║███████║
  ██║      ██║   ██║██║  ██║██╔══██║
  ╚██████╗ ╚██████╔╝██████╔╝██║  ██║
   ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝

  Comprehensive On-chain Defense Arsenal v2.0.0
  15 tools. 1 command. Zero missed vulnerabilities.
  Developed by @aloc999 (Hashemi)

Target: ./my-defi-protocol
Report: ./my-defi-protocol/coda-report-20260101-120000

[1/15] Running Slither static analysis...
  ✓ Slither complete
[2/15] Running Mythril symbolic execution...
  ✓ Mythril complete
[3/15] Running Semgrep custom rules...
  ✓ Semgrep complete
[4/15] Running Securify2 formal static analysis...
  ✓ Securify2 complete
[5/15] Running Surya visualization...
  ✓ Surya complete
[6/15] Running secret scanner...
  ✓ Gitleaks complete
[7/15] Running Echidna property fuzzer...
  ✓ Echidna complete
[8/15] Running Medusa coverage fuzzer...
  ✓ Medusa complete
[9/15] Running Foundry invariant tests...
  ✓ Foundry invariant complete
[10/15] Running Grep Arsenal pattern scan...
  ✓ Grep Arsenal complete
[11/15] Running Halmos symbolic testing...
  ✓ Halmos complete
[12/15] Running Manticore symbolic execution...
  ✓ Manticore complete
[13/15] Running Certora formal verification...
  ✓ Certora submitted (check https://prover.certora.com)
[14/15] Running Gambit mutation testing...
  ✓ Gambit complete (120 mutants generated)
[15/15] Running Scribble + Differential fuzzing...
  ✓ Complete

════════════════════════════════════════
  CODA audit complete!
  15 tools executed
  Report: ./my-defi-protocol/coda-report-20260101-120000
════════════════════════════════════════
```

## Requirements

- Linux/macOS
- Python 3.8+
- Node.js 16+ (for Foundry/npm-based projects)
- Rust/Cargo (for Aderyn — optional)
- 4GB+ RAM recommended for fuzzing

## License

MIT License — see [LICENSE](LICENSE) file.

## Credits

CODA integrates these open-source tools:
- [Slither](https://github.com/crytic/slither) — Trail of Bits
- [Mythril](https://github.com/ConsenSys/mythril) — ConsenSys
- [Echidna](https://github.com/crytic/echidna) — Trail of Bits
- [Medusa](https://github.com/crytic/medusa) — Trail of Bits
- [Foundry](https://github.com/foundry-rs/foundry) — Paradigm
- [Halmos](https://github.com/a16z/halmos) — a16z
- [Certora Prover](https://www.certora.com/) — Certora
- [Gambit](https://github.com/Certora/gambit) — Certora
