//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Invest} from "../src/Invest.sol";
import {Wallet} from "../src/wallet.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./TestInterface/IWeth.sol";

contract InvestTest is Test {
    Wallet wallet;
    Invest invest;
    address owner = makeAddr("owner");
    address _pool = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address uniswapAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IWETH iweth = IWETH(wethAddress);
    uint256 mainnetFork;

    function setUp() external {
        mainnetFork = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/1QklE9_Cfl51BruLBXMMRqY1hNRPLK0E");
        vm.selectFork(mainnetFork);
        vm.deal(owner, 100 ether);
        vm.prank(owner);
        iweth.deposit{value: 10 ether}();
        invest = new Invest(_pool,uniswapAddress, wethAddress);
        wallet = new Wallet(address(invest),owner, IERC20(wethAddress), wethAddress, 1);
        invest.setUpWallet(address(wallet));
        vm.prank(owner);
        iweth.transfer(address(wallet), 10 ether);
    }

    function testSupplyLiquidityRevertIfzero() external {
        vm.expectRevert(Invest.NeedMoreThanZero.selector);
        invest.supplyInAaveProtocol(wethAddress, 0);
    }

    function testSupplyInAaveProtocolRevertIfZeroAddress() external {
        vm.expectRevert(Invest.NotZeroAddress.selector);
        invest.supplyInAaveProtocol(address(0), 100);
    }

    function testSupplyRevertIfTokenIsNotVestedAnymore() external {
        vm.expectRevert(Invest.TokenNotAvailable.selector);
        invest.supplyInAaveProtocol(wethAddress, 1000);
    }
    function testTokenIsSuppliedProperly() external {
    invest.supplyInAaveProtocol(wethAddress,5 ether);
    address _atoken= invest.getATokenAddress(); 
    assert(IERC20(_atoken).balanceOf(address(invest)) != 0); 
    console.log(IERC20(_atoken).balanceOf(address(invest)) );
    }
    
    function testGetAddresses() external view {
        console.log(invest.getATokenAddress());
        console.log(invest.getPoleAddress());
        
    }
    function testHarvest() external {
        invest.supplyInAaveProtocol(wethAddress,5 ether);
        invest.harvest(address(0));
    }
    function testWithdrawIsWorkingProperly() external {
         invest.supplyInAaveProtocol(wethAddress,5 ether);
         invest._withdrawFromAave(5 ether, address(this));
         assertEq(iweth.balanceOf(address(this)), 5 ether);
         console.log(iweth.balanceOf(address(this)));
    }
    
}
