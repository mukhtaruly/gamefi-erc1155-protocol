// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {MockERC20} from "../src/MockERC20.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";

contract ResourceAMMTest is Test {
    MockERC20 tokenA;
    MockERC20 tokenB;

    ResourceAMM amm;

    address player = address(1);
    address playerTwo = address(2);

    function setUp() public {
        tokenA = new MockERC20("Gold", "GLD");

        tokenB = new MockERC20("Mana", "MANA");

        amm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.transfer(player, 1000 ether);
        tokenB.transfer(player, 1000 ether);
        tokenA.transfer(playerTwo, 1000 ether);
        tokenB.transfer(playerTwo, 1000 ether);

        vm.startPrank(player);

        tokenA.approve(address(amm), type(uint256).max);

        tokenB.approve(address(amm), type(uint256).max);

        vm.stopPrank();

        vm.startPrank(playerTwo);

        tokenA.approve(address(amm), type(uint256).max);

        tokenB.approve(address(amm), type(uint256).max);

        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(player);

        amm.addLiquidity(100 ether, 100 ether);

        vm.stopPrank();

        assertEq(amm.reserveA(), 100 ether);

        assertEq(amm.reserveB(), 100 ether);

        assertEq(amm.lpToken().balanceOf(player), 100 ether);
    }

    function testSwap() public {
        vm.startPrank(player);

        amm.addLiquidity(100 ether, 100 ether);

        uint256 amountOut = amm.swapAForB(10 ether, 1 ether);

        vm.stopPrank();

        assertEq(amountOut, 9066108938801491315);

        assertEq(tokenB.balanceOf(player), 900 ether + amountOut);

        assertEq(amm.reserveA(), 110 ether);

        assertEq(amm.reserveB(), 100 ether - amountOut);
    }

    function testSwapBForA() public {
        vm.startPrank(player);

        amm.addLiquidity(100 ether, 100 ether);

        uint256 amountOut = amm.swapBForA(10 ether, 1 ether);

        vm.stopPrank();

        assertEq(amountOut, 9066108938801491315);

        assertEq(tokenA.balanceOf(player), 900 ether + amountOut);
    }

    function testRemoveLiquidity() public {
        vm.startPrank(player);

        amm.addLiquidity(100 ether, 100 ether);

        uint256 lpBalance = amm.lpToken().balanceOf(player);

        amm.removeLiquidity(lpBalance);

        vm.stopPrank();

        assertEq(amm.reserveA(), 0);

        assertEq(amm.reserveB(), 0);

        assertEq(tokenA.balanceOf(player), 1000 ether);

        assertEq(tokenB.balanceOf(player), 1000 ether);
    }

    function testSecondProviderGetsProportionalLpTokens() public {
        vm.prank(player);

        amm.addLiquidity(100 ether, 100 ether);

        vm.prank(playerTwo);

        amm.addLiquidity(50 ether, 50 ether);

        assertEq(amm.lpToken().balanceOf(player), 100 ether);

        assertEq(amm.lpToken().balanceOf(playerTwo), 50 ether);
    }

    function testRejectsWrongLiquidityRatio() public {
        vm.prank(player);

        amm.addLiquidity(100 ether, 100 ether);

        vm.prank(playerTwo);

        vm.expectRevert(ResourceAMM.InvalidRatio.selector);

        amm.addLiquidity(50 ether, 40 ether);
    }

    function testSwapRespectsSlippageLimit() public {
        vm.startPrank(player);

        amm.addLiquidity(100 ether, 100 ether);

        vm.expectRevert(ResourceAMM.InsufficientOutput.selector);

        amm.swapAForB(10 ether, 10 ether);

        vm.stopPrank();
    }

    function testRejectsZeroInitialLiquidity() public {
        vm.prank(player);
        vm.expectRevert(ResourceAMM.InvalidAmount.selector);
        amm.addLiquidity(0, 100 ether);
    }

    function testRejectsInvalidRemoveLiquidity() public {
        vm.prank(player);
        vm.expectRevert(ResourceAMM.InvalidLiquidity.selector);
        amm.removeLiquidity(1 ether);
    }

    function testRejectsSwapWithoutLiquidity() public {
        vm.prank(player);
        vm.expectRevert(ResourceAMM.InvalidLiquidity.selector);
        amm.swapAForB(1 ether, 0);
    }

    function testGetAmountOutRejectsZeroAmount() public {
        vm.expectRevert(ResourceAMM.InvalidAmount.selector);
        amm.getAmountOut(0, 100 ether, 100 ether);
    }
}
