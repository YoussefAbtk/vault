//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IWETH} from "../test/TestInterface/IWeth.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Wallet is Ownable, ERC4626{
    using Math for uint256; 
    using SafeERC20 for IERC20;
    error FailingToSendEth();
    error NotEnoughtEth();
    error NotEnoughtToken();
    error OnlyInvest();
    error NoDeposit();
    error NotEnoughtTime(); 
    error Allowance();

    address s_invest;
    address s_owner;
    IERC20 s_asset;
    address immutable i_wrapper; 
    uint256 immutable i_interval; 
    
    mapping(bytes32=> uint256) s_depositToTimestamp;

    constructor(address _invest, address _owner, IERC20 _asset, address _wrapper, uint256 _interval) payable Ownable(_owner) ERC4626(_asset) ERC20("Vault Token", "VLT"){
        s_invest = _invest;
        s_owner = _owner;
        s_asset =_asset; 
        i_wrapper = _wrapper; 
        i_interval = _interval; 
    }

    modifier onlyInvest() {
        if (msg.sender != s_invest && msg.sender!= address(this)) {
            revert OnlyInvest();
        }
        _;
    }


    function getBalanceToken(address token) public view returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));
    }

    function getBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }
    

   
    
    function depositEth() payable public returns(uint256 shares) {
        address _wrapper =i_wrapper; 
        IWETH(_wrapper).deposit(); 
        IWETH(_wrapper).transfer(msg.sender,IWETH(_wrapper).balanceOf(address(this))); 
        uint256 userBalance = IWETH(_wrapper).balanceOf(msg.sender); 
       shares = deposit( userBalance, msg.sender); 

    }
    function deposit(uint256 assets, address receiver) public override returns(uint256) {
        uint256 sharesExpected = previewDeposit(assets) ; 
        bytes32 depositId = keccak256(abi.encode(msg.sender, assets, sharesExpected)); 
        s_depositToTimestamp[depositId] = block.timestamp; 

       uint256 shares =  super.deposit(assets, receiver); 
       return shares; 
    }
    function transferFundsToInvest( uint256 amount ) public onlyInvest {
        s_asset.safeTransfer(s_invest, amount);
    }
    function withdrawFromInvest() external {
        
    }
    function depositAndInvest(uint256 amount) external {
        deposit( amount, msg.sender); 
        transferFundsToInvest(amount); 

    }
    function withdraw(uint256 assets, address receiver, address owner) public override returns(uint256) {
         uint256 sharesExpected = previewDeposit(assets) ; 
          bytes32 depositId = keccak256(abi.encode(owner, assets, sharesExpected)); 
          if(s_depositToTimestamp[depositId]==0) {
            revert NoDeposit(); 
          } else if(block.timestamp - s_depositToTimestamp[depositId] < i_interval) {
            revert NotEnoughtTime();
          }
          uint256 shares = super.withdraw(assets, receiver, owner); 
          return shares; 
        

        
    }

    receive() external payable {
        depositEth(); 
    }

}
