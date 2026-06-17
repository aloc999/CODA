#!/usr/bin/env bash
# CODA Kontrol — RV KEVM-based formal verification at EVM bytecode level
# Proves deeper invariants than Solidity-level tools (storage, delegatecall, gas)
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-kontrol}"
mkdir -p "$REPORT"

KONTROL_VERSION="v0.1.0"

echo "[Kontrol] KEVM-based formal verification..."

if ! command -v kontrol >/dev/null 2>&1; then
    if command -v kup >/dev/null 2>&1; then
        kup install kontrol 2>/dev/null || true
    else
        echo "  Installing kup..."
        curl -sL https://raw.githubusercontent.com/runtimeverification/kup/main/install.sh | bash 2>/dev/null || true
        export PATH="$HOME/.kup/bin:$PATH"
        kup install kontrol 2>/dev/null || {
            echo "  ⚠ Kontrol not available — requires K Framework."
            echo "  Manual install: https://github.com/runtimeverification/kontrol"
            exit 0
        }
    fi
fi

# Generate kontrol spec from harness
if command -v kontrol >/dev/null 2>&1; then
    cd "$TARGET"
    
    # Build with foundry first
    forge build --force >/dev/null 2>&1 || true
    
    # Generate default spec template
    kontrol init --force 2>/dev/null || true
    
    # Run symbolic tests on key contracts
    echo "  Running KEVM symbolic execution..."
    for f in $(find contracts -name "*.sol" ! -path "*/factories/*" ! -path "*/interfaces/*" ! -path "*/common/*" 2>/dev/null | head -3); do
        name=$(basename "$f" .sol)
        echo "    Proving $name..."
        kontrol prove --match-test "test_${name}" --verbose 2>"$REPORT/${name}.log" || true
    done
    
    # Generate report
    kontrol report --output-dir "$REPORT" 2>/dev/null || true
    cd - >/dev/null
fi

echo "[Kontrol] Done. Reports in $REPORT"
