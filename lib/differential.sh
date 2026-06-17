#!/usr/bin/env bash
# CODA Differential Fuzzing — compares two contract implementations for discrepancy
# If function A and function B should produce the same result, this catches when they don't
set -euo pipefail

TARGET="${1:-.}"
REPORT="${2:-/tmp/coda-differential}"

echo "[Differential Fuzz] Setting up..."
mkdir -p "$REPORT"

# Generate differential fuzz template for the project
cat > "$TARGET/test/DifferentialFuzz.t.sol" << 'SOLIDITY'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// @title Differential Fuzz Test
/// @notice Compares behavior of two functions that should be equivalent.
/// CODA auto-generated template — customize for your protocol.
contract DifferentialFuzzTest is Test {
    // ============================================
    // CONFIGURE THESE FOR YOUR PROTOCOL
    // ============================================

    // Example 1: buy() vs onTokenTransfer() in Crowdinvesting
    // function testFuzz_differential_buy_vs_onTokenTransfer(uint256 amount) public {
    //     amount = bound(amount, 1e15, 1e24);
    //     uint256 costA = buyPath(amount);
    //     uint256 costB = onTokenTransferPath(amount);
    //     assertApproxEqRel(costA, costB, 0.01e18, "Paths differ by more than 1%");
    // }

    // Example 2: mint() vs deposit() in ERC4626 vault
    // function testFuzz_differential_mint_vs_deposit(uint256 assets) public {
    //     assets = bound(assets, 1, 1e24);
    //     uint256 sharesA = vault.convertToShares(assets);
    //     vault.deposit(assets, address(this));
    //     uint256 sharesB = vault.balanceOf(address(this));
    //     assertApproxEqRel(sharesA, sharesB, 0.001e18, "Deposit math drift");
    // }

    // ============================================
    // BOILERPLATE
    // ============================================

    function setUp() public virtual {
        // Deploy your contracts here
    }

    // Add your path A helper
    // function pathA(uint256 x) internal returns (uint256) { ... }

    // Add your path B helper
    // function pathB(uint256 x) internal returns (uint256) { ... }
}
SOLIDITY

echo "[Differential Fuzz] Template generated at test/DifferentialFuzz.t.sol"
echo "  Edit the test to add your protocol's function pairs, then run:"
echo "  forge test --match-contract DifferentialFuzz --fuzz-runs 1000"

# If Foundry is available, try compiling
if command -v forge >/dev/null 2>&1; then
    cd "$TARGET"
    forge build --skip test 2>/dev/null || true
    cd - >/dev/null
fi

echo "[Differential Fuzz] Done."
