//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IWallet {
    function sendEth(address payable receiver, uint256 amount) external payable;
    function getBalanceToken(address token) external view returns (uint256 balance);
    function giveAllowanceToInvest(address token, uint256 amount) external;
    function giveAllowanceToProtocol(address token, uint256 amount, address protocol) external; 
    function transferFundsToInvest( uint256 amount ) external; 
}
