# CODA — Comprehensive On-chain Defense Arsenal

**9 tools. 1 command. Zero missed vulnerabilities.**

CODA is an all-in-one smart contract audit toolkit that integrates 9 battle-tested security tools into a single, unified workflow. Run a full audit with one command.

## Tools Included

| # | Tool | Type | What It Catches |
|---|------|------|----------------|
| 1 | **Slither** | Static Analysis | Reentrancy, access control, uninitialized state, 91 detectors |
| 2 | **Mythril** | Symbolic Execution | Integer overflow, unprotected selfdestruct, reachability |
| 3 | **Echidna** | Property Fuzzing | Invariant violations via 50K+ random call sequences |
| 4 | **Medusa** | Coverage Fuzzing | Deep state exploration with multi-core parallelism |
| 5 | **Foundry** | Invariant Testing | Full-suite invariant fuzzing with real contract state |
| 6 | **Grep Arsenal** | Pattern Scan | 50+ vulnerability patterns (reentrancy, oracle, proxy) |
| 7 | **Halmos** | Symbolic Proving | Prove properties for ALL inputs (not just sampled) |
| 8 | **Certora Prover** | Formal Verification | Cloud-based formal verification of access control + invariants |
| 9 | **Gambit** | Mutation Testing | Verify test suite catches every behavioral deviation |

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
coda audit /path/to/your/smart-contract-project

# Or run individual phases:
coda static /path/to/project     # Slither + Grep (fast, ~2 min)
coda symbolic /path/to/project   # Mythril + Halmos (medium, ~10 min)
coda fuzz /path/to/project       # Echidna + Medusa + Foundry (deep, ~15 min)
coda formal /path/to/project     # Certora Prover (requires API key)
coda mutation /path/to/project   # Gambit mutation testing
coda quick /path/to/project      # Fast audit (Slither + Grep + Mythril)
coda report /path/to/project     # Generate final audit report
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
Quick audit (Slither + Grep + Mythril)      ~3 min    →  First pass
Symbolic (Mythril + Halmos)                  ~10 min   →  Prove critical paths
Fuzzing (Echidna + Medusa + Foundry)         ~15 min   →  Break invariants
Formal verification (Certora)                ~10 min   →  Cloud formal proof
Mutation testing (Gambit)                    ~15 min   →  Test suite coverage
────────────────────────────────────────────────────────
FULL AUDIT                                   ~50 min   →  All 9 tools
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

  Comprehensive On-chain Defense Arsenal v1.0.0
  9 tools. 1 command. Zero missed vulnerabilities.

Target: ./my-defi-protocol
Report: ./my-defi-protocol/coda-report-20260101-120000

[1/9] Running Slither static analysis...
  ✓ Slither complete
[2/9] Running Mythril symbolic execution...
  ✓ Mythril complete
[3/9] Running Echidna property fuzzer...
  ✓ Echidna complete
[4/9] Running Medusa coverage fuzzer...
  ✓ Medusa complete
[5/9] Running Foundry invariant tests...
  ✓ Foundry invariant complete
[6/9] Running Grep Arsenal pattern scan...
  ✓ Grep Arsenal complete
[7/9] Running Halmos symbolic testing...
  ✓ Halmos complete
[8/9] Running Certora formal verification...
  ✓ Certora submitted (check https://prover.certora.com)
[9/9] Running Gambit mutation testing...
  ✓ Gambit complete (120 mutants generated)

════════════════════════════════════════
  CODA audit complete!
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
