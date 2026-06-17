#!/usr/bin/env bash
# CODA Semgrep — Custom pattern matching with Solidity-specific rules
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-semgrep}"

echo "[Semgrep] Installing..."
if ! command -v semgrep >/dev/null 2>&1; then
    pip3 install semgrep --break-system-packages 2>/dev/null || pip3 install semgrep 2>/dev/null || {
        echo "  ⚠ Semgrep not available — skipping"
        exit 0
    }
fi

echo "[Semgrep] Running Solidity security rules..."
mkdir -p "$REPORT"

# Run with Solidity-specific rules
semgrep scan \
    --config auto \
    --include "*.sol" \
    --exclude "test/**" \
    --exclude "node_modules/**" \
    --exclude "lib/**" \
    --json \
    -o "$REPORT/semgrep-auto.json" \
    "$TARGET" 2>/dev/null || true

# Run CODA custom rules for additional patterns
RULESDIR="${SCRIPT_DIR:-./lib}/../rules"
if [ -d "$RULESDIR/semgrep" ]; then
    semgrep scan \
        --config "$RULESDIR/semgrep" \
        --include "*.sol" \
        --json \
        -o "$REPORT/semgrep-custom.json" \
        "$TARGET" 2>/dev/null || true
fi

# Run specific high-value patterns
semgrep scan \
    --config "p/solidity" \
    --include "*.sol" \
    --sarif \
    -o "$REPORT/semgrep-sarif.sarif" \
    "$TARGET" 2>/dev/null || true

# Summary
echo "[Semgrep] Summary:"
python3 -c "
import json, sys
try:
    with open('$REPORT/semgrep-auto.json') as f:
        data = json.load(f)
    results = data.get('results', [])
    print(f'  Auto findings: {len(results)}')
    for r in results[:5]:
        print(f'    - {r.get(\"check_id\", \"?\")}  in {r.get(\"path\", \"?\").split(\"/\")[-1]}')
except: pass
" 2>/dev/null

echo "[Semgrep] Done. Reports in $REPORT"
