Alchemix WstETH Adapter Zero Slippage Vulnerability PoC
Hey there! I've put together this repo to show off a pretty nasty vulnerability I found in Alchemix's WstETH adapters. The issue? They hardcode slippage protection to zero when unwrapping tokens, which opens the door for some serious sandwich attacks.

## What's The Bug?
Found this while digging through Alchemix's code. The vulnerability exists in:

WstETHAdapter.sol (Ethereum) - Line 164
WstETHAdapterOptimism.sol (Optimism) - Line 114
Check this out - they're setting slippage to ZERO when exchanging through Curve/Velodrome:

In WstETHAdapter.sol:
```
// Line 164: slippage is hardcoded to 0 (yikes!)
uint256 received = IStableSwap2Pool(curvePool).exchange(int128(uint128(stEthPoolIndex)), int128(uint128(ethPoolIndex)), unwrappedStEth, 0);
```
In WstETHAdapterOptimism.sol:
```
// Line 114: they pass the deadline but minAmount is 0 (no protection at all)
uint256[] memory amounts = IVelodromeRouter(velodromeRouter).swapExactTokensForTokens(
    underlyingAmount,
    0,  // <-- This should NOT be zero
    path,
    address(this),
    block.timestamp
);
```
## Running My PoC
What You'll Need
Foundry installed
An Ethereum Mainnet RPC URL
Setting up RPC URL
This test forks mainnet at block 18500000, so it needs an Ethereum RPC endpoint.

1-export MAINNET_RPC_URL=https://ethereum-mainnet-rpc-url 

2-Or direct in command: forge test -vv --match-test testWstETHSlippageVulnerability --rpc-url=https://ethereum-mainnet-rpc-url

## Running The Test
Just one command: forge test -vv --match-test testWstETHSlippageVulnerability

## What The Test Shows
My PoC demonstrates:

Normal expected ETH from withdrawal: 30 ETH
Actual ETH received after my attack: 20 ETH
Victim's loss: 10 ETH (33% of their funds - ouch!)
My profit as an attacker: 8 ETH (after accounting for gas/costs)
Look at results/exploit-results.txt for the full output if you want the details.

## How The Attack Works
1-I watch the mempool for juicy large withdrawal transactions
2-Front-run that tx by manipulating the Curve pool price with a flash loan
3-Let the victim's withdrawal execute with the manipulated price (they have zero slippage protection)
4-Back-run to restore the pool price and pocket my profit

It's a classic sandwich attack but way more profitable because there's literally no protection against it.

## How To Fix It
The adapters should respect the slippage parameter that's already being passed from the Alchemist contract:

For WstETHAdapter.sol:
```
// Change this:
uint256 received = IStableSwap2Pool(curvePool).exchange(int128(uint128(stEthPoolIndex)), int128(uint128(ethPoolIndex)), unwrappedStEth, 0);

// To this:
uint256 received = IStableSwap2Pool(curvePool).exchange(int128(uint128(stEthPoolIndex)), int128(uint128(ethPoolIndex)), unwrappedStEth, unwrappedStEth * minAmountOut / underlyingAmount);
```
For WstETHAdapterOptimism.sol:
```
// Change this:
uint256[] memory amounts = IVelodromeRouter(velodromeRouter).swapExactTokensForTokens(
    underlyingAmount,
    0,
    path,
    address(this),
    block.timestamp
);

// To this:
uint256[] memory amounts = IVelodromeRouter(velodromeRouter).swapExactTokensForTokens(
    underlyingAmount,
    minAmountOut,  // <-- Use the actual parameter!
    path,
    address(this),
    block.timestamp
);
```
Pretty simple fix for a potentially expensive problem. One line of code making all the difference.