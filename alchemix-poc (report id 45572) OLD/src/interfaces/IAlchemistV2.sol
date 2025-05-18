// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAlchemistV2 {
    function withdrawUnderlying(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256);
    
    function liquidate(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external returns (uint256);
    
    function deposit(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external;
    
    function mint(
        uint256 amount,
        address recipient
    ) external;
    
    function convertSharesToUnderlyingTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (uint256);
    
    function convertSharesToYieldTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (uint256);
}