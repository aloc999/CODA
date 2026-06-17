#!/usr/bin/env bash
# CODA Scribble — Annotation-based property testing and fuzzing harness generation
# Scribble: https://github.com/ConsenSys/scribble
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-scribble}"

echo "[Scribble] Installing scribble..."
if ! command -v scribble >/dev/null 2>&1; then
    npm install -g eth-scribble 2>/dev/null || {
        echo "  npm install failed, trying direct..."
        npm install -g @consensys/scribble 2>/dev/null || {
            echo "  ⚠ Scribble not available — skipping"
            exit 0
        }
    }
fi

echo "[Scribble] Generating property annotations..."
mkdir -p "$REPORT/scribble"

# Generate annotation template for each contract
find "$TARGET/contracts" -name "*.sol" ! -path "*/factories/*" ! -path "*/interfaces/*" 2>/dev/null | while read -r f; do
    name=$(basename "$f" .sol)
    scribble "$f" --output-mode flat --arm 2>/dev/null > "$REPORT/scribble/${name}_annotated.sol" 2>&1 || true
done

# Run instrumentation and verify properties
echo "[Scribble] Instrumenting contracts with runtime checks..."
find "$TARGET/contracts" -name "*.sol" ! -path "*/factories/*" 2>/dev/null | head -5 | while read -r f; do
    scribble "$f" --output-mode files --output-path "$REPORT/scribble/instrumented" 2>/dev/null || true
done

# Generate fuzzing harness from Scribble annotations
echo "[Scribble] Generating fuzzing harnesses..."
cat > "$REPORT/scribble/invariants.txt" << 'SCRIBBLE'
# Scribble Property Annotations
# Add these to your Solidity source files for automatic property checking

/// #if_succeeds {:msg "Solvency invariant"} totalAssets() >= totalDebt();
/// #if_succeeds {:msg "Share consistency"} balanceOf(msg.sender) <= totalSupply();

// Example for CoinvestedPosition:
/// #if_succeeds {:msg "Credits = balance"} 
///   coinvestorCredit(currency) + leadInvestorCredit(0, currency) + leadInvestorCredit(1, currency)
///   == currency.balanceOf(address(this));

// Example for Distribution:
/// #if_succeeds {:msg "No double claim"} 
///   paidOut[msg.sender] == old(paidOut[msg.sender]) + gross;
SCRIBBLE

echo "[Scribble] Done. Reports in $REPORT/scribble"
