#!/usr/bin/env bash
# CODA Phalcon — BlockSec on-chain attack pattern detection
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-phalcon}"
mkdir -p "$REPORT"

echo "[Phalcon] On-chain attack pattern analysis..."

# Phalcon is a web-based tool (blocksec.com/phalcon)
# We generate the necessary data and provide instructions

# Collect deployed contract addresses from project config
echo "[Phalcon] Collecting deployment addresses..."

# Check deploy scripts for addresses
find "$TARGET" -name "*.json" -path "*/deployments/*" -o -name "*.json" -path "*/broadcast/*" 2>/dev/null | while read -r f; do
    python3 -c "
import json
with open('$f') as fp:
    data = json.load(fp)
    if 'transactions' in data:
        for tx in data['transactions']:
            if 'contractAddress' in tx:
                print(f\"  Contract: {tx['contractName']} → {tx['contractAddress']}\")
    if 'address' in data:
        print(f\"  {data.get('contractName','?')}: {data['address']}\")
" 2>/dev/null
done > "$REPORT/addresses.txt"

# Generate Phalcon URL for each contract
echo "[Phalcon] Analysis links:"
cat "$REPORT/addresses.txt" 2>/dev/null | while read -r line; do
    addr=$(echo "$line" | grep -oE "0x[a-fA-F0-9]{40}" | head -1)
    if [ -n "$addr" ]; then
        echo "  https://app.blocksec.com/explorer/tx/ethereum/${addr}"
    fi
done

# Off-chain: use their API if key is set
if [ -n "${BLOCKSEC_API_KEY:-}" ]; then
    echo "[Phalcon] Running API scan..."
    curl -s -H "API-Key: $BLOCKSEC_API_KEY" \
        "https://api.phalcon.blocksec.com/v1/scan" \
        -d @- > "$REPORT/phalcon-api.json" 2>&1 <<< '{"chain":"ethereum"}'
fi

echo "[Phalcon] Done. Open https://app.blocksec.com/explorer"
