#!/usr/bin/env bash
# CODA Grep Arsenal — pattern-based vulnerability scanning
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-grep}"
mkdir -p "$REPORT"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

header() { echo -e "\n${GREEN}=== $1 ===${NC}" >> "$REPORT/grep-arsenal.txt"; }

header "CODA Grep Arsenal Report — $(date)"

# Block 1: Access Control
header "ACCESS CONTROL"
tx_origin=$(grep -rn "tx\.origin" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "tx.origin usage: ${tx_origin}" >> "$REPORT/grep-arsenal.txt"

silent_mod=$(grep -rn "modifier " "$TARGET/contracts" --include="*.sol" -A8 2>/dev/null | grep -B3 "if (" | grep -v "require\|revert" || echo "none")
echo "Silent modifiers (if without revert): ${silent_mod}" >> "$REPORT/grep-arsenal.txt"

# Block 2: Reentrancy
header "REENTRANCY"
raw_call=$(grep -rn "\.call{value\|\.call(" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "Raw .call() usage: ${raw_call}" >> "$REPORT/grep-arsenal.txt"

transfer=$(grep -rn "\.transfer(\|\.send(" "$TARGET/contracts" 2>/dev/null || echo "none")
echo ".transfer/.send usage: ${transfer}" >> "$REPORT/grep-arsenal.txt"

nonreentrant_count=$(grep -rn "nonReentrant" "$TARGET/contracts" --include="*.sol" 2>/dev/null | wc -l)
echo "nonReentrant modifiers: ${nonreentrant_count}" >> "$REPORT/grep-arsenal.txt"

# Block 3: Oracle / Price
header "ORACLE / PRICE"
slot0=$(grep -rn "slot0\b" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "slot0() (Uniswap V3 spot): ${slot0}" >> "$REPORT/grep-arsenal.txt"

getReserves=$(grep -rn "getReserves()" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "getReserves() (V2 spot): ${getReserves}" >> "$REPORT/grep-arsenal.txt"

latestRound=$(grep -rn "latestRoundData\|latestAnswer" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "Chainlink oracle: ${latestRound}" >> "$REPORT/grep-arsenal.txt"

# Block 4: Arithmetic
header "ARITHMETIC"
unchecked=$(grep -rn "unchecked {" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "unchecked blocks: ${unchecked}" >> "$REPORT/grep-arsenal.txt"

div_first=$(grep -rn "/ totalSupply\|/ totalAssets\|\b/ \b" "$TARGET/contracts" --include="*.sol" 2>/dev/null | head -20 || echo "none")
echo "Division before multiply: ${div_first}" >> "$REPORT/grep-arsenal.txt"

# Block 5: Proxy / Upgrade
header "PROXY / UPGRADE"
initialize=$(grep -rn "function initialize\|_disableInitializers\|initializer" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "Initializer pattern: ${initialize}" >> "$REPORT/grep-arsenal.txt"

authorize=$(grep -rn "_authorizeUpgrade" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "_authorizeUpgrade: ${authorize}" >> "$REPORT/grep-arsenal.txt"

delegatecall=$(grep -rn "delegatecall" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "delegatecall usage: ${delegatecall}" >> "$REPORT/grep-arsenal.txt"

# Block 6: Signatures
header "SIGNATURES"
ecrecover=$(grep -rn "ecrecover\|ECDSA\.recover" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "ecrecover usage: ${ecrecover}" >> "$REPORT/grep-arsenal.txt"

chainid=$(grep -rn "chainId\|block\.chainid\|DOMAIN_SEPARATOR" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "chainId references: ${chainid}" >> "$REPORT/grep-arsenal.txt"

nonce=$(grep -rn "nonces\[" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "nonce tracking: ${nonce}" >> "$REPORT/grep-arsenal.txt"

# Block 7: Token Handling
header "TOKEN HANDLING"
balanceOf=$(grep -rn "balanceOf(address(this))" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "balanceOf(this) usage: ${balanceOf}" >> "$REPORT/grep-arsenal.txt"

safeERC20=$(grep -rn "SafeERC20\|safeTransfer\b" "$TARGET/contracts" --include="*.sol" 2>/dev/null | wc -l)
echo "SafeERC20 usage count: ${safeERC20}" >> "$REPORT/grep-arsenal.txt"

# Block 8: Decimal precision
header "DECIMAL PRECISION"
wad=$(grep -rn "/ 1e18\|/ WAD\|/ 10\*\*18" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "Hardcoded /1e18: ${wad}" >> "$REPORT/grep-arsenal.txt"

decimals_fn=$(grep -rn "decimals()" "$TARGET/contracts" --include="*.sol" 2>/dev/null || echo "none")
echo "decimals() calls: ${decimals_fn}" >> "$REPORT/grep-arsenal.txt"

# Block 9: Business logic
header "BUSINESS LOGIC"
updateFunc=$(grep -rn "function update\|function set" "$TARGET/contracts" --include="*.sol" -A3 2>/dev/null | grep -E "onlyOwner|onlyRole" | wc -l)
echo "Protected update functions: ${updateFunc}" >> "$REPORT/grep-arsenal.txt"

# Block 10: Events on critical changes
header "EVENT COVERAGE"
emit_count=$(grep -rn "emit " "$TARGET/contracts" --include="*.sol" 2>/dev/null | wc -l)
echo "Total emit statements: ${emit_count}" >> "$REPORT/grep-arsenal.txt"

echo -e "\n${GREEN}Grep Arsenal complete. Report: $REPORT/grep-arsenal.txt${NC}"
