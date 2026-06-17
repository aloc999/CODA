#!/usr/bin/env bash
# CODA Brownie — Python-based testing and integration framework integration
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-brownie}"

echo "[Brownie] Setting up..."
mkdir -p "$REPORT"

if ! command -v brownie >/dev/null 2>&1; then
    pip3 install eth-brownie --break-system-packages 2>/dev/null || pip3 install eth-brownie 2>/dev/null || {
        echo "  ⚠ Brownie not available — skipping"
        exit 0
    }
fi

# Run Brownie analysis
echo "[Brownie] Running static analysis..."
cd "$TARGET"

# brownie analyze (slither-like but integrated)
brownie analyze 2>/dev/null > "$REPORT/brownie-analyze.txt" || true

# brownie test (Python-based integration tests)
if [ -d tests ]; then
    brownie test --gas 2>/dev/null > "$REPORT/brownie-tests.txt" || true
fi

# Generate coverage
brownie test --coverage 2>/dev/null > "$REPORT/brownie-coverage.txt" || true

cd - >/dev/null

echo "[Brownie] Done. Reports in $REPORT"
