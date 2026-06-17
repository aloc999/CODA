#!/usr/bin/env bash
# CODA Wake — Ackee Blockchain's Python framework with 30+ vulnerability detectors
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-wake}"
mkdir -p "$REPORT"

echo "[Wake] Python-based analysis (30+ detectors)..."

if ! command -v wake >/dev/null 2>&1; then
    pip3 install eth-wake --break-system-packages 2>/dev/null || pip3 install eth-wake 2>/dev/null || {
        echo "  ⚠ Wake not available — skipping"
        echo "  Install: pip3 install eth-wake"
        exit 0
    }
fi

if command -v wake >/dev/null 2>&1; then
    cd "$TARGET"

    # Initialize wake project
    wake init --force 2>/dev/null || true

    # Run all detectors
    echo "  Running Wake detectors..."
    wake detect all --silent > "$REPORT/wake-detect.txt" 2>&1 || true

    # Run with specific detector categories
    echo "  Deep scanning: access control, reentrancy, arithmetic..."
    wake detect access-control reentrancy arithmetic --json \
        > "$REPORT/wake-critical.json" 2>&1 || true

    # Print call graph
    echo "  Generating call graph..."
    wake print call-graph --format dot > "$REPORT/wake-callgraph.dot" 2>/dev/null || true

    # Print inheritance graph
    echo "  Generating inheritance graph..."
    wake print inheritance-graph --format dot > "$REPORT/wake-inheritance.dot" 2>/dev/null || true

    # Control flow graph
    wake print control-flow-graph --function _credit > "$REPORT/wake-cfg-credit.dot" 2>/dev/null || true

    # LSP features
    echo "  Running LSP analysis..."
    wake lsp compile 2>/dev/null || true

    cd - >/dev/null

    # Convert dot to SVG if graphviz available
    if command -v dot >/dev/null 2>&1; then
        for f in "$REPORT"/*.dot; do
            [ -f "$f" ] && dot -Tsvg "$f" -o "${f%.dot}.svg" 2>/dev/null || true
        done
    fi
fi

echo "[Wake] Done. Reports in $REPORT"
