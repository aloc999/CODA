#!/usr/bin/env bash
# CODA Gitleaks — Secret and credential scanning
# Catches: private keys, API keys, mnemonics, tokens, passwords
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-gitleaks}"

echo "[Gitleaks] Scanning for hardcoded secrets..."

if command -v gitleaks >/dev/null 2>&1; then
    gitleaks detect --source "$TARGET" \
        --report-path "$REPORT/gitleaks.json" \
        --report-format json \
        --verbose 2>/dev/null || true
    
    gitleaks detect --source "$TARGET" \
        --report-path "$REPORT/gitleaks.sarif" \
        --report-format sarif \
        --verbose 2>/dev/null || true
else
    # Pure bash-based secret scanning as fallback
    echo "  (using built-in secret scanner — install gitleaks for deeper scanning)"
    
    mkdir -p "$REPORT"
    
    # Patterns to scan for
    patterns=(
        "0x[0-9a-fA-F]{64}"                           # Private keys
        "0x[0-9a-fA-F]{40}"                           # Ethereum addresses (potential keys)
        "[a-z]+_[a-zA-Z0-9]{32,}"                     # Common API key patterns
        "sk-[a-zA-Z0-9]{32,}"                          # OpenAI/Stripe-style keys
        "[A-Z0-9]{20,}-[a-zA-Z0-9]{20,}"             # JWT-style tokens
        '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'  # Private keys
        'ghp_[a-zA-Z0-9]{36}'                          # GitHub tokens
        'github_pat_[a-zA-Z0-9_]{40,}'                # GitHub fine-grained PATs
        'Infura\|Alchemy\|QuickNode'                   # Provider API key mentions
        'password\s*[:=]\s*["\x27][^"\x27]{4,}'        # Passwords
        'secret\s*[:=]\s*["\x27][^"\x27]{4,}'         # Secrets
        'mnemonic\|seed phrase\|recovery phrase'       # Crypto mnemonics
    )
    
    echo "Scanning for ${#patterns[@]} secret patterns..."
    for pattern in "${patterns[@]}"; do
        matches=$(grep -rnE "$pattern" "$TARGET" \
            --include="*.sol" --include="*.js" --include="*.ts" \
            --include="*.json" --include="*.env" --include="*.toml" \
            --include="*.yaml" --include="*.yml" --include="*.md" \
            --include="*.sh" --include="*.py" \
            --exclude-dir="node_modules" --exclude-dir="lib" \
            --exclude-dir=".git" --exclude-dir="cache" --exclude-dir="out" \
            2>/dev/null | grep -v "0x0000000000000000000000000000000000000000\|constants\|test\|mock\|example" || true)
        if [ -n "$matches" ]; then
            echo "⚠ Pattern matched: $pattern"
            echo "$matches" >> "$REPORT/secrets.txt"
        fi
    done
fi

# Summary
if [ -f "$REPORT/secrets.txt" ]; then
    count=$(wc -l < "$REPORT/secrets.txt")
    echo "  Found $count potential secret references"
    echo "  Review manually before treating as real leaks"
else
    echo "  No secrets detected"
fi

echo "[Gitleaks] Done."
