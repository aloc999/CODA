/*
 * CODA Certora Specification Template
 * 
 * Replace YOUR_CONTRACT with your main contract name.
 * Add your rules and invariants.
 */

methods {
    // Declare envfree view functions
    // function totalSupply() external returns (uint256) envfree;
    // function balanceOf(address) external returns (uint256) envfree;
    
    // Summarize external calls
    // function _.transfer(address, uint256) external => DISPATCHER(true);
    // function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
}

/*
 * RULE: Only authorized users can withdraw
 */
// rule onlyOwnerCanWithdraw(method f, uint256 amount) 
//     filtered { f -> f.selector == sig:withdraw(uint256).selector }
// {
//     env e;
//     require e.msg.sender != owner();
//     withdraw@withrevert(e, amount);
//     assert lastReverted, "Non-owner should not withdraw";
// }

/*
 * INVARIANT: Contract is always solvent
 */
// invariant solvency()
//     totalAssets() >= totalDebt();

/*
 * RULE: Deposit correctly updates state
 */
// rule depositCorrect(uint256 amount) {
//     env e;
//     uint256 sharesBefore = balanceOf(e.msg.sender);
//     uint256 assetsBefore = totalAssets();
//     deposit(e, amount);
//     uint256 sharesAfter = balanceOf(e.msg.sender);
//     assert sharesAfter > sharesBefore || amount == 0;
// }
