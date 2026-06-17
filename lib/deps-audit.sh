#!/usr/bin/env bash
# CODA Dependency Audit — npm audit + Snyk + yarn audit + pip audit
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-deps}"
mkdir -p "$REPORT"

echo "[Deps] Auditing dependencies..."

total_issues=0

# npm audit
if [ -f "$TARGET/package.json" ]; then
    echo "  Running npm audit..."
    cd "$TARGET"
    npm audit --json > "$REPORT/npm-audit.json" 2>&1 || true
    npm audit --audit-level=critical 2>&1 | grep -E "Critical|High|Moderate" > "$REPORT/npm-critical.txt" || true
    cd - >/dev/null
fi

# yarn audit
if [ -f "$TARGET/yarn.lock" ]; then
    echo "  Running yarn audit..."
    cd "$TARGET"
    yarn audit --json > "$REPORT/yarn-audit.json" 2>&1 || true
    cd - >/dev/null
fi

# pip audit (Python dependencies)
if command -v pip-audit >/dev/null 2>&1; then
    echo "  Running pip-audit..."
    pip-audit --format json -o "$REPORT/pip-audit.json" 2>&1 || true
elif command -v safety >/dev/null 2>&1; then
    echo "  Running safety check..."
    safety check --json --output "$REPORT/safety-check.json" 2>&1 || true
fi

# Snyk (more comprehensive but needs auth)
if command -v snyk >/dev/null 2>&1; then
    echo "  Running Snyk scan..."
    cd "$TARGET"
    snyk test --json > "$REPORT/snyk.json" 2>&1 || true
    snyk code test --json > "$REPORT/snyk-code.json" 2>&1 || true
    cd - >/dev/null
else
    echo "  ⚠ Snyk CLI not installed. Install: npm install -g snyk && snyk auth"
fi

# Foundry submodule audit
if [ -f "$TARGET/.gitmodules" ]; then
    echo "  Auditing git submodules..."
    cd "$TARGET"
    git submodule foreach 'echo "=== $name ===" && git log --oneline -5' > "$REPORT/submodules.txt" 2>&1 || true
    cd - >/dev/null
fi

# Solidity-specific: check for known vulnerable OZ versions
echo "  Checking Solidity dependency versions..."
find "$TARGET/node_modules/@openzeppelin" -name "package.json" -maxdepth 2 2>/dev/null | while read -r pkg; do
    ver=$(python3 -c "import json; print(json.load(open('$pkg')).get('version','?'))" 2>/dev/null || echo "?")
    echo "    OZ version: $ver ($pkg)"
done >> "$REPORT/sol-deps.txt"

echo "[Deps] Done. Reports in $REPORT"
