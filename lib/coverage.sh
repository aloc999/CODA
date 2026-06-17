#!/usr/bin/env bash
# CODA Solidity Coverage — Granular line/branch/function coverage analysis
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-coverage}"
mkdir -p "$REPORT"

echo "[Coverage] Analyzing test coverage..."

# Foundry coverage (primary)
if command -v forge >/dev/null 2>&1; then
    cd "$TARGET"
    echo "  Running Foundry coverage..."
    FOUNDRY_PROFILE="${FOUNDRY_PROFILE:-default}"

    forge coverage \
        --no-match-path "test/{legacy,backwards-compatibility}/**" \
        --no-match-contract "ExitSafe|Mainnet" \
        --report lcov \
        --report-file "$REPORT/lcov.info" 2>&1 | tail -5 || true

    forge coverage \
        --no-match-path "test/{legacy,backwards-compatibility}/**" \
        --no-match-contract "ExitSafe|Mainnet" \
        --report summary > "$REPORT/coverage-summary.txt" 2>&1 || true

    # Extract coverage percentages
    echo "  Per-contract coverage:" > "$REPORT/coverage.txt"
    grep -E "contracts/" "$REPORT/coverage-summary.txt" 2>/dev/null | head -30 >> "$REPORT/coverage.txt" || true
    cd - >/dev/null
fi

# solidity-coverage (hardhat — if available)
if command -v hardhat >/dev/null 2>&1 && [ -f "$TARGET/hardhat.config.js" ]; then
    echo "  Running Hardhat solidity-coverage..."
    cd "$TARGET"
    npx hardhat coverage --solcoverjs .solcover.js > "$REPORT/hardhat-coverage.txt" 2>&1 || true
    cd - >/dev/null
fi

# LCOV to HTML
if command -v genhtml >/dev/null 2>&1; then
    genhtml "$REPORT/lcov.info" -o "$REPORT/html" 2>/dev/null || true
    echo "  HTML report: $REPORT/html/index.html"
fi

# Highlight uncovered lines
echo "[Coverage] Uncovered analysis:"
grep -E "\| [0-9]{1,2}\.[0-9]{2}%" "$REPORT/coverage.txt" 2>/dev/null | \
    awk '{ if ($2 < 90) print "  LOW:  " $1 " — " $2 }' || true
grep -E "100\.00%" "$REPORT/coverage.txt" 2>/dev/null | \
    awk '{ print "  FULL: " $1 " — " $2 }' || true

echo "[Coverage] Done."
