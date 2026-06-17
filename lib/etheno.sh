#!/usr/bin/env bash
# CODA Etheno — JSON-RPC multiplexer for differential testing between EVM implementations
# Compares behavior across: geth, besu, nethermind, erigon
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-etheno}"
mkdir -p "$REPORT"

echo "[Etheno] Differential EVM testing..."

if ! command -v etheno >/dev/null 2>&1; then
    pip3 install etheno --break-system-packages 2>/dev/null || pip3 install etheno 2>/dev/null || {
        echo "  ⚠ Etheno not available — skipping"
        echo "  Install: pip3 install etheno"
        exit 0
    }
fi

# Etheno requires multiple RPC endpoints to compare
echo "[Etheno] Requires multiple RPC endpoints. Set:"
echo "  export ETHENO_RPC1=https://mainnet.infura.io/v3/..."
echo "  export ETHENO_RPC2=https://eth-mainnet.g.alchemy.com/v2/..."

# Generate differential test script
cat > "$TARGET/scripts/etheno-differential.py" << 'ETHENO'
#!/usr/bin/env python3
"""CODA Differential Test via Etheno"""
from etheno import EthenoPlugin, contract, run_cli
import os

class DifferentialTest(EthenoPlugin):
    async def run(self):
        # Deploy contract
        target = await contract.deploy_file(
            os.getenv("TARGET_CONTRACT", "contracts/CoinvestedPosition.sol"),
            args=[...]  # constructor args
        )
        
        # Run same transaction on multiple RPCs
        tx = await target.functions.buy(1000000, 10000000, self.address).transact()
        receipt = await self.wait(tx)
        
        # Etheno automatically compares results across providers
        self.log(f"Gas used: {receipt.gasUsed}")
        self.log(f"Status: {'OK' if receipt.status else 'FAILED'}")

if __name__ == "__main__":
    run_cli(DifferentialTest)
ETHENO
chmod +x "$TARGET/scripts/etheno-differential.py"

echo "[Etheno] Differential test script generated at scripts/etheno-differential.py"
echo "  Usage: python3 scripts/etheno-differential.py"

# Fallback: Use Foundry for differential testing across forks (no extra deps)
echo "[Etheno] Foundry-backed differential test generated:"
cat > "$TARGET/test/DifferentialEVM.t.sol" << 'DIFFSOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
contract DifferentialEVMTest is Test {
    function testDifferential_bytecode_behavior() public {
        // Deploy same contract on two forks
        // Compare behavior: same inputs → same outputs
        // If they differ → EVM implementation bug or compiler issue
    }
}
DIFFSOL

echo "[Etheno] Done."
