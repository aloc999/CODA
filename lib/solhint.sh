#!/usr/bin/env bash
# CODA Solhint — Solidity linter for code quality, style, and best practices
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-solhint}"
mkdir -p "$REPORT"

echo "[Solhint] Solidity linter..."

if ! command -v solhint >/dev/null 2>&1; then
    npm install -g solhint 2>/dev/null || {
        echo "  ⚠ Solhint not available — skipping"
        echo "  Install: npm install -g solhint"
        exit 0
    }
fi

# Generate solhint config
cat > "$TARGET/.solhint.json" << 'SOLHINTCFG'
{
  "extends": "solhint:recommended",
  "plugins": [],
  "rules": {
    "avoid-suicide": "error",
    "avoid-sha3": "error",
    "avoid-throw": "error",
    "avoid-tx-origin": "error",
    "check-send-result": "error",
    "compiler-version": ["error", "^0.8.0"],
    "func-visibility": ["warn", { "ignoreConstructors": true }],
    "no-complex-fallback": "error",
    "no-inline-assembly": "warn",
    "not-rely-on-block-hash": "error",
    "not-rely-on-time": "warn",
    "reentrancy": "error",
    "state-visibility": "error",
    "var-name-mixedcase": "warn",
    "func-name-mixedcase": "warn",
    "max-line-length": ["warn", 120],
    "no-empty-blocks": "warn",
    "no-unused-vars": "error",
    "payable-fallback": "warn",
    "reason-string": ["warn", { "maxLength": 64 }],
    "constructor-syntax": "error",
    "func-param-name-mixedcase": "warn",
    "modifier-name-mixedcase": "warn",
    "private-vars-leading-underscore": "warn",
    "use-forbidden-name": "error",
    "named-parameters-mapping": "warn",
    "no-console": "error",
    "no-global-import": "warn",
    "no-unused-import": "error",
    "explicit-types": ["warn", "explicit"],
    "one-contract-per-file": "warn",
    "ordering": "warn",
    "immutable-vars-naming": ["warn", { "immutablesAsConstants": true }],
    "comprehensive-interface": "warn"
  }
}
SOLHINTCFG

echo "[Solhint] Linting contracts..."
cd "$TARGET"

# Run solhint
solhint --formatter stylish "contracts/**/*.sol" > "$REPORT/solhint-stylish.txt" 2>&1 || true
solhint --formatter json "contracts/**/*.sol" > "$REPORT/solhint.json" 2>&1 || true

# Count issues by severity
echo "[Solhint] Summary:"
errors=$(grep -c '"error"' "$REPORT/solhint.json" 2>/dev/null || echo "0")
warns=$(grep -c '"warn"' "$REPORT/solhint.json" 2>/dev/null || echo "0")
echo "  Errors: $errors"
echo "  Warnings: $warns"

cd - >/dev/null
echo "[Solhint] Done. Reports in $REPORT"
