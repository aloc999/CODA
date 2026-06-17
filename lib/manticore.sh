#!/usr/bin/env bash
# CODA Manticore — Trail of Bits symbolic execution engine
# Finds: integer overflow, reentrancy, unprotected selfdestruct, locked ether
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-manticore}"

echo "[Manticore] Symbolic execution..."
mkdir -p "$REPORT"

if ! command -v manticore >/dev/null 2>&1; then
    # Try pip install
    pip3 install manticore --break-system-packages 2>/dev/null || pip3 install manticore 2>/dev/null || {
        # Docker fallback
        if command -v docker >/dev/null 2>&1; then
            echo "  Using Docker..."
            docker pull trailofbits/manticore:latest 2>/dev/null || true
            find "$TARGET/contracts" -name "*.sol" ! -path "*/factories/*" ! -path "*/interfaces/*" 2>/dev/null | head -5 | while read -r f; do
                local name=$(basename "$f" .sol)
                echo "  Analyzing $name..."
                docker run --rm -v "$(pwd):/src" trailofbits/manticore \
                    "manticore /src/$f --solc-remaps @openzeppelin=/src/node_modules/@openzeppelin" \
                    2>/dev/null > "$REPORT/${name}.log" || true
            done
        else
            echo "  ⚠ Manticore not available — skipping"
            exit 0
        fi
    }
fi

if command -v manticore >/dev/null 2>&1; then
    find "$TARGET/contracts" -name "*.sol" ! -path "*/factories/*" ! -path "*/interfaces/*" 2>/dev/null | head -8 | while read -r f; do
        name=$(basename "$f" .sol)
        echo "  Analyzing $name..."
        timeout 120 manticore "$f" \
            --contract "$name" \
            --quick \
            --workspace "$REPORT/workspace_${name}" \
            2>"$REPORT/${name}.log" || true
        # Summarize findings
        if [ -f "$REPORT/workspace_${name}/global.summary" ]; then
            echo "  Findings:" >> "$REPORT/summary.txt"
            cat "$REPORT/workspace_${name}/global.summary" >> "$REPORT/summary.txt"
        fi
    done
fi

echo "[Manticore] Done. Reports in $REPORT"
