#!/usr/bin/env bash
# CODA Rattle — EVM bytecode-to-SSA lifter by Trail of Bits
# Finds: compiler bugs, constructor logic, initcode issues
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-rattle}"
mkdir -p "$REPORT"

echo "[Rattle] Bytecode SSA analysis..."

if ! command -v rattle >/dev/null 2>&1; then
    pip3 install rattle-analyzer --break-system-packages 2>/dev/null || pip3 install rattle-analyzer 2>/dev/null || {
        # Clone and build from source
        if [ ! -d /tmp/rattle ]; then
            git clone https://github.com/trailofbits/rattle /tmp/rattle 2>/dev/null || true
        fi
        if [ -d /tmp/rattle ]; then
            pip3 install -e /tmp/rattle --break-system-packages 2>/dev/null || true
        fi
        if ! command -v rattle >/dev/null 2>&1; then
            echo "  ⚠ Rattle not available — skipping"
            exit 0
        fi
    }
fi

# First compile contracts to bytecode
echo "  Compiling contracts for bytecode extraction..."
cd "$TARGET"
forge build --force >/dev/null 2>&1 || true

# Find compiled bytecode files
if [ -d out ]; then
    find out -name "*.json" ! -name "*test*" ! -name "*Test*" ! -name "*Mock*" 2>/dev/null | grep -v ".metadata" | head -10 | while read -r artifact; do
        name=$(basename "$artifact" .json)
        bytecode=$(python3 -c "import json; print(json.load(open('$artifact')).get('bytecode',{}).get('object',''))" 2>/dev/null || echo "")
        if [ -n "$bytecode" ] && [ "$bytecode" != "" ]; then
            echo "  Analyzing $name..."
            echo "$bytecode" > "$REPORT/${name}.hex"
            rattle -i "$REPORT/${name}.hex" -o "$REPORT/${name}.ssa" 2>/dev/null || true
        fi
    done
fi
cd - >/dev/null

# Summarize
echo "[Rattle] Analysis complete."
find "$REPORT" -name "*.ssa" | while read -r f; do
    size=$(wc -l < "$f")
    echo "  $(basename "$f" .ssa): ${size} SSA instructions"
done

echo "[Rattle] Done. Reports in $REPORT"
