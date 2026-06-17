#!/usr/bin/env bash
# CODA Trufflehog — Full git history secret scanning
# Scans entire commit history, not just current files
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-trufflehog}"
mkdir -p "$REPORT"

echo "[Trufflehog] Scanning full git history for secrets..."

if ! command -v trufflehog >/dev/null 2>&1; then
    # Download binary
    curl -sL "https://github.com/trufflesecurity/trufflehog/releases/download/v3.81.0/trufflehog_3.81.0_linux_amd64.tar.gz" \
        -o /tmp/trufflehog.tar.gz
    tar xzf /tmp/trufflehog.tar.gz -C "$HOME/.local/bin/" trufflehog 2>/dev/null || {
        # Pip fallback
        pip3 install trufflehog 2>/dev/null || {
            echo "  ⚠ Trufflehog not available — skipping"
            exit 0
        }
    }
    chmod +x "$HOME/.local/bin/trufflehog" 2>/dev/null || true
fi

export PATH="$HOME/.local/bin:$PATH"

if command -v trufflehog >/dev/null 2>&1; then
    cd "$TARGET"

    # Scan git history (all commits, all branches)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "  Scanning git history..."
        trufflehog git file://. --json --only-verified > "$REPORT/trufflehog-git.json" 2>&1 || true
    fi

    # Scan filesystem
    echo "  Scanning filesystem..."
    trufflehog filesystem . --json --only-verified --exclude-paths node_modules,lib,out,cache,forge-std,test \
        > "$REPORT/trufflehog-fs.json" 2>&1 || true

    # Scan specific high-value paths
    echo "  Deep scanning config files..."
    trufflehog filesystem . --include-paths "**.json,**.toml,**.env,**.yaml,**.yml,**.ts,**.js" \
        --exclude-paths "node_modules,lib,out,package-lock.json" \
        --json --only-verified >> "$REPORT/trufflehog-config.json" 2>&1 || true
    cd - >/dev/null
fi

# Summary
echo "[Trufflehog] Results:"
for f in "$REPORT"/trufflehog-*.json; do
    if [ -f "$f" ]; then
        count=$(grep -c "}" "$f" 2>/dev/null || echo "0")
        echo "  $(basename "$f"): $count findings"
    fi
done

echo "[Trufflehog] Done."
