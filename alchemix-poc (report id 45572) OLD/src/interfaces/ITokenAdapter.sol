// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenAdapter {
    function version() external view returns (string memory);
    function token() external view returns (address);
    function underlyingToken() external view returns (address);
    function price() external view returns (uint256);
    
    function wrap(uint256 amount, address recipient)
        external
        returns (uint256 amountYieldTokens);
        
    function unwrap(uint256 amount, address recipient)
        external
        returns (uint256 amountUnderlyingTokens);
}