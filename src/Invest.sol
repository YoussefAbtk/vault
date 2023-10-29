//SPDX-License-Identifier: MIT

import {Wallet} from "./wallet.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWallet} from "../src/interfaces/IWallet.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/interfaces/ISwapRouter.sol";
import {IPoolDataProvider} from "@aave/core-v3/contracts/interfaces/IPoolDataProvider.sol";
import {IAToken} from "@aave/core-v3/contracts/interfaces/IAToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAaveV3Incentives} from "./interfaces/IincentiveController.sol";


pragma solidity ^0.8.10;

contract Invest {
    using SafeERC20 for IERC20; 
    error TokenNotAvailable();
    error NeedMoreThanZero();
    error NotZeroAddress();
    error Allowance();
    error NotWallet(); 

    address owner;
    IPool immutable i_pool;
    IWallet  i_wallet;
    IPoolAddressesProvider immutable i_address_Provider;
    IAToken immutable i_aToken; 
    ISwapRouter immutable i_router; 
    IPoolDataProvider immutable i_dataProvider; 
    address constant INCENTIVE = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    address i_weth;
    address constant output= 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    constructor(address _addressProvider,  address _router, address _weth) {
        i_address_Provider = IPoolAddressesProvider(_addressProvider);
        i_dataProvider= IPoolDataProvider(i_address_Provider.getPoolDataProvider()); 
       
       (address _aToken,,)= i_dataProvider.getReserveTokensAddresses(_weth);
        i_aToken = IAToken(_aToken);
        i_pool = IPool(i_address_Provider.getPool());
        i_router = ISwapRouter(_router); 
        i_weth = _weth; 
        
    }

    function setUpWallet(address _wallet) external {
        i_wallet = IWallet(_wallet);
    }
  

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert NeedMoreThanZero();
        }
        _;
    }
    modifier onlyWallet() {
        if(msg.sender != address(i_wallet)){
revert NotWallet();
        }
    _;
    }

  function withdraw(uint256 amount, address to) external  {
    if(amount==0) {
        revert NeedMoreThanZero();
    } 
    if(to == address(0)) {
        revert NotZeroAddress();
    }

_withdrawFromAave(amount,  to);
  }
function _withdrawFromAave( uint256 amount, address to) private {
i_pool.withdraw(i_weth, amount, to);
}
    function _supplyLiquidityInAave( uint256 amount) private moreThanZero(amount) {
        IERC20 _token = IERC20(i_weth);
        if (IERC20(_token).balanceOf(address(i_wallet)) == 0) {
            revert TokenNotAvailable();
        }
        
        uint16 referalCode = 0;
        i_wallet.transferFundsToInvest( amount); 
        _token.approve(address(i_pool), amount);
        //i_wallet.giveAllowanceToProtocol(token, amount,0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8); 
        i_pool.supply(address(i_weth), amount, address(this), referalCode);
        
    }
    function harvest(address callrecepient) external  {
       address[] memory assets = new address[](1); 
       assets[0]=address(i_aToken); 
       uint256 rewards = IAaveV3Incentives(INCENTIVE).claimRewards(assets, type(uint256).max, address(this));
       chargeFees(callrecepient, rewards);
       uint256 amountOut = _uniswapRouterSwap(address(i_aToken), i_weth,0,rewards-(rewards*3) /100); 
      _supplyLiquidityInAave(amountOut);
    }
    function chargeFees(address callFeeRecipient, uint256 rewards ) internal {
        uint256 keeperReward= (rewards*3) /100;
        IERC20(output).safeTransfer(callFeeRecipient, keeperReward);

    }

    function _uniswapRouterSwap(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn
    ) private returns (uint amountOut) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(i_router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = i_router.exactInputSingle(params);
    }

    function supplyInAaveProtocol( uint256 amount) external {
        _supplyLiquidityInAave( amount);
    }
    function getATokenAddress() external view returns(address){
        return address(i_aToken);
    }
    function getPoleAddress() external view returns(address){
        return address(i_pool);
    }
    

}
