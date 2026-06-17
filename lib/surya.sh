#!/usr/bin/env bash
# CODA Surya — Contract visualization, inheritance graphs, function summaries
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-surya}"

echo "[Surya] Installing..."
if ! command -v surya >/dev/null 2>&1; then
    npm install -g surya 2>/dev/null || {
        echo "  ⚠ Surya not available — install with: npm install -g surya"
        exit 0
    }
fi

echo "[Surya] Generating contract visualizations..."
mkdir -p "$REPORT"

# Inheritance graph
echo "  - inheritance graph"
surya inheritance "$TARGET/contracts/"**/*.sol 2>/dev/null | \
    dot -Tsvg -o "$REPORT/inheritance.svg" 2>/dev/null || \
    surya inheritance "$TARGET/contracts/"**/*.sol > "$REPORT/inheritance.dot" 2>/dev/null || true

# Function call graph
echo "  - function call graph"
surya ftrace "$TARGET/contracts/"**/*.sol all 2>/dev/null | \
    dot -Tsvg -o "$REPORT/callgraph.svg" 2>/dev/null || true

# Contract descriptions
echo "  - contract descriptions"
surya describe "$TARGET/contracts/"**/*.sol 2>/dev/null > "$REPORT/describe.txt" || true

# Function summary
echo "  - function summary"
surya mdreport "$REPORT/surya-report.md" "$TARGET/contracts/"**/*.sol 2>/dev/null || true

# Parse markdown for complexity metrics
echo "  - complexity analysis"
surya parse "$TARGET/contracts/"**/*.sol 2>/dev/null > "$REPORT/parse.json" || true

# Dependency graph between contracts
echo "  - dependency graph"
surya graph "$TARGET/contracts/"**/*.sol 2>/dev/null | \
    dot -Tsvg -o "$REPORT/dependencies.svg" 2>/dev/null || true

echo "[Surya] Done. Reports in $REPORT"
