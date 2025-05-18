Alchemix WstETH Adapter Slippage Vulnerability
This repository demonstrates a critical vulnerability in Alchemix Protocol that affects the WstETH adapter contracts. The vulnerability allows attackers to execute profitable sandwich attacks against users withdrawing funds, potentially leading to substantial losses.

The Vulnerability
The core issue involves slippage protection being completely bypassed in two different ways:

Original Discovery
Our first proof-of-concept (in the alchemix-exploit-poc folder) demonstrates that the WstETH adapters hardcode slippage protection to zero when unwrapping tokens:
```
// In WstETHAdapter.sol
uint256 received = IStableSwap2Pool(curvePool).exchange(
    int128(uint128(stEthPoolIndex)), 
    int128(uint128(ethPoolIndex)), 
    unwrappedStEth, 
    0  // <-- Hardcoded to ZERO
);
```
This PoC shows how attackers can manipulate prices in the Curve pool before a victim's withdrawal executes, causing them to receive significantly less ETH than expected with no protection whatsoever.

Response to Immunefi's Assessment
After submitting the report, Immunefi responded that slippage protection is actually handled at the AlchemistV2 contract level, not in the adapters.

Our second PoC (in the alchemix-updated-exploit folder) proves this assessment incomplete by showing the vulnerability persists even with AlchemistV2's checks. The key problem is:
```
// From AlchemistV2.sol:

// First they check the expected amount
if (minimumAmountOut > 0) {
    if (adapter.unwrap(shares, 0) < minimumAmountOut) {
        revert SlippageError();
    }
}

// Then they execute with zero protection anyway
amount = adapter.unwrap(shares, 0);  // Still using 0!
```
This creates a window of opportunity between the check and the actual execution where an attacker can manipulate prices, bypassing the slippage check completely.

Impact
The demonstrated impact is severe:

Users can lose up to 33% of their funds in a single withdrawal
Every user who sets a slippage value believes they're protected when they're not
The attack can be executed against any significant withdrawal from these contracts
Attackers can earn substantial profits with minimal risk
Security Implications
This vulnerability represents a critical security flaw because:

It breaks a core security promise of the protocol (slippage protection)
It affects all users withdrawing from these contracts
It could lead to substantial financial losses
It exists in production code currently securing millions in user funds
Recommended Fix
The solution is straightforward - ensure proper slippage protection throughout the entire execution flow:
```
// In AlchemistV2.sol, change:
amount = adapter.unwrap(shares, 0);

// To:
amount = adapter.unwrap(shares, minimumAmountOut);
```
This simple one-line fix would properly protect users from sandwich attacks during withdrawals.
