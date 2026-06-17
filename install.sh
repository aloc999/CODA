#!/usr/bin/env bash
# CODA Installer — installs all 9 audit tools
set -eu

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     CODA — Tool Installation         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

# 1. Foundry (forge, cast, anvil)
echo -e "${YELLOW}[1/9] Installing Foundry...${NC}"
if ! command -v forge >/dev/null 2>&1; then
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    foundryup
else
    echo "  Already installed: $(forge --version 2>&1 | head -1)"
fi

# 2. Slither
echo -e "${YELLOW}[2/9] Installing Slither...${NC}"
if ! command -v slither >/dev/null 2>&1; then
    pip3 install slither-analyzer --break-system-packages 2>/dev/null || pip3 install slither-analyzer
else
    echo "  Already installed: $(slither --version 2>&1)"
fi

# 3. Mythril
echo -e "${YELLOW}[3/9] Installing Mythril...${NC}"
if ! command -v myth >/dev/null 2>&1; then
    pip3 install mythril --break-system-packages 2>/dev/null || pip3 install mythril
else
    echo "  Already installed: $(myth version 2>&1 | head -1)"
fi

# 4. Echidna
echo -e "${YELLOW}[4/9] Installing Echidna...${NC}"
if ! command -v echidna >/dev/null 2>&1; then
    ECHIDNA_VER="2.2.5"
    curl -sL "https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VER}/echidna-${ECHIDNA_VER}-x86_64-linux.tar.gz" \
        -o /tmp/echidna.tar.gz
    tar xzf /tmp/echidna.tar.gz -C "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/echidna"
else
    echo "  Already installed: $(echidna --version 2>&1)"
fi

# 5. Medusa
echo -e "${YELLOW}[5/9] Installing Medusa...${NC}"
if ! command -v medusa >/dev/null 2>&1; then
    MEDUSA_VER="0.1.8"
    curl -sL "https://github.com/crytic/medusa/releases/download/v${MEDUSA_VER}/medusa-linux-x64.tar.gz" \
        -o /tmp/medusa.tar.gz
    tar xzf /tmp/medusa.tar.gz -C "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/medusa"
else
    echo "  Already installed: $(medusa --version 2>&1)"
fi

# 6. Halmos
echo -e "${YELLOW}[6/9] Installing Halmos...${NC}"
if ! command -v halmos >/dev/null 2>&1; then
    pip3 install halmos --break-system-packages 2>/dev/null || pip3 install halmos
else
    echo "  Already installed: $(halmos --version 2>&1)"
fi

# 7. Certora CLI
echo -e "${YELLOW}[7/9] Installing Certora CLI...${NC}"
if ! command -v certoraRun >/dev/null 2>&1; then
    pip3 install certora-cli --break-system-packages 2>/dev/null || pip3 install certora-cli
else
    echo "  Already installed: $(certoraRun --version 2>&1)"
fi
if [ -z "${CERTORA_KEY:-}" ]; then
    echo -e "${RED}  ⚠ Set CERTORA_KEY env var for formal verification: export CERTORA_KEY=your_key${NC}"
fi

# 8. Gambit
echo -e "${YELLOW}[8/9] Installing Gambit...${NC}"
if ! command -v gambit >/dev/null 2>&1; then
    GAMBIT_VER="1.0.6"
    curl -sL "https://github.com/Certora/gambit/releases/download/v${GAMBIT_VER}/gambit-linux-v${GAMBIT_VER}" \
        -o "$INSTALL_DIR/gambit"
    chmod +x "$INSTALL_DIR/gambit"
else
    echo "  Already installed: $(gambit --help 2>&1 | head -1)"
fi

# 9. Semgrep
echo -e "${YELLOW}[9/15] Installing Semgrep...${NC}"
if ! command -v semgrep >/dev/null 2>&1; then
    pip3 install semgrep --break-system-packages 2>/dev/null || pip3 install semgrep
else
    echo "  Already installed: $(semgrep --version 2>&1 | head -1)"
fi

# 10. Surya
echo -e "${YELLOW}[10/15] Installing Surya...${NC}"
if ! command -v surya >/dev/null 2>&1; then
    npm install -g surya 2>/dev/null || echo "  ⚠ Optional — skip with: npm install -g surya"
else
    echo "  Already installed"
fi

# 11. Gitleaks
echo -e "${YELLOW}[11/15] Installing Gitleaks...${NC}"
if ! command -v gitleaks >/dev/null 2>&1; then
    curl -sL "https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz" \
        -o /tmp/gitleaks.tar.gz
    tar xzf /tmp/gitleaks.tar.gz -C "$INSTALL_DIR/" gitleaks 2>/dev/null || true
    chmod +x "$INSTALL_DIR/gitleaks" 2>/dev/null || true
else
    echo "  Already installed: $(gitleaks version 2>&1 | head -1)"
fi

# 12. Manticore
echo -e "${YELLOW}[12/15] Installing Manticore...${NC}"
if ! command -v manticore >/dev/null 2>&1; then
    pip3 install manticore --break-system-packages 2>/dev/null || {
        echo "  ⚠ Manticore build failed — use Docker: docker pull trailofbits/manticore"
    }
else
    echo "  Already installed: $(manticore --version 2>&1 | head -1)"
fi

# 13. Brownie
echo -e "${YELLOW}[13/15] Installing Brownie...${NC}"
if ! command -v brownie >/dev/null 2>&1; then
    pip3 install eth-brownie --break-system-packages 2>/dev/null || pip3 install eth-brownie
else
    echo "  Already installed: $(brownie --version 2>&1 | head -1)"
fi

# 14. Scribble
echo -e "${YELLOW}[14/15] Installing Scribble...${NC}"
if ! command -v scribble >/dev/null 2>&1; then
    npm install -g eth-scribble 2>/dev/null || npm install -g @consensys/scribble 2>/dev/null || \
        echo "  ⚠ Optional — skip with: npm install -g eth-scribble"
else
    echo "  Already installed"
fi

# 15. solc (via solc-select)
echo -e "${YELLOW}[15/15] Installing solc 0.8.34...${NC}"
if ! command -v solc >/dev/null 2>&1; then
    pip3 install solc-select --break-system-packages 2>/dev/null || pip3 install solc-select
    solc-select install 0.8.34
    solc-select use 0.8.34
else
    echo "  Already installed: $(solc --version 2>&1 | grep Version)"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  CODA installed!                     ║${NC}"
echo -e "${GREEN}║  Run: coda audit <target-project>    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
echo ""
echo "Add to your shell config:"
echo "  export PATH=\"\$HOME/.foundry/bin:\$HOME/.local/bin:\$PATH\""
echo "  export FOUNDRY_SOLC=\"\$(which solc)\""
echo "  export CERTORA_KEY=\"your_key\"  # optional"
