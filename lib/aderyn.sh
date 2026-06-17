#!/usr/bin/env bash
# CODA Aderyn — Cyfrin's Rust-based static analyzer with DeFi-specific detectors
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-aderyn}"
mkdir -p "$REPORT"

echo "[Aderyn] Rust-based static analysis..."

if ! command -v aderyn >/dev/null 2>&1; then
    # Try downloading prebuilt binary
    ADERYN_VER="0.6.8"
    curl -sL "https://github.com/Cyfrin/aderyn/releases/download/aderyn-v${ADERYN_VER}/aderyn-x86_64-unknown-linux-gnu.tar.xz" \
        -o /tmp/aderyn.tar.xz
    tar xJf /tmp/aderyn.tar.xz -C "$HOME/.local/bin/" --strip-components=1 2>/dev/null || {
        # Try cargo install (slower)
        if command -v cargo >/dev/null 2>&1; then
            cargo install aderyn 2>/dev/null &
            echo "  Installing via cargo (background)..."
            wait
        else
            echo "  ⚠ Aderyn not available — skipping"
            exit 0
        fi
    }
    chmod +x "$HOME/.local/bin/aderyn" 2>/dev/null || true
fi

if command -v aderyn >/dev/null 2>&1; then
    echo "  Running Aderyn on contracts..."
    cd "$TARGET"
    
    # Aderyn auto-detects Foundry projects
    aderyn --src contracts/ -o "$REPORT/aderyn-report.md" 2>&1 | tail -10 || true
    
    # Also output JSON for programmatic analysis
    aderyn --src contracts/ -o "$REPORT/aderyn-report.md" 2>&1 > "$REPORT/aderyn-output.txt" || true
    
    cd - >/dev/null
else
    echo "  ⚠ Aderyn binary not found after install attempt"
fi

echo "[Aderyn] Done."
