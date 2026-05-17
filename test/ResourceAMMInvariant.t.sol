// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";

import {MockERC20} from "../src/MockERC20.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";

contract ResourceAMMHandler is Test {
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    ResourceAMM public amm;

    uint256 public lastK;

    constructor(MockERC20 tokenA_, MockERC20 tokenB_, ResourceAMM amm_) {
        tokenA = tokenA_;
        tokenB = tokenB_;
        amm = amm_;
        lastK = amm.getK();
    }

    function swapAForB(uint256 amountIn) external {
        amountIn = bound(amountIn, 1, 5 ether);
        tokenA.approve(address(amm), amountIn);
        amm.swapAForB(amountIn, 0);
        lastK = amm.getK();
    }

    function swapBForA(uint256 amountIn) external {
        amountIn = bound(amountIn, 1, 5 ether);
        tokenB.approve(address(amm), amountIn);
        amm.swapBForA(amountIn, 0);
        lastK = amm.getK();
    }
}

contract ResourceAMMInvariantTest is StdInvariant, Test {
    MockERC20 tokenA;
    MockERC20 tokenB;
    ResourceAMM amm;
    ResourceAMMHandler handler;

    uint256 initialK;

    function setUp() public {
        tokenA = new MockERC20("Gold", "GLD");
        tokenB = new MockERC20("Mana", "MANA");
        amm = new ResourceAMM(address(tokenA), address(tokenB));

        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        amm.addLiquidity(1_000 ether, 1_000 ether);
        initialK = amm.getK();

        handler = new ResourceAMMHandler(tokenA, tokenB, amm);
        tokenA.transfer(address(handler), 100_000 ether);
        tokenB.transfer(address(handler), 100_000 ether);

        targetContract(address(handler));
    }

    function invariantKDoesNotDecreaseDuringSwaps() public view {
        assertGe(amm.getK(), initialK);
    }

    function invariantSupplyConservation() public view {
        assertEq(
            tokenA.balanceOf(address(amm)) + tokenA.balanceOf(address(handler)) + tokenA.balanceOf(address(this)),
            1_000_000 ether
        );
        assertEq(
            tokenB.balanceOf(address(amm)) + tokenB.balanceOf(address(handler)) + tokenB.balanceOf(address(this)),
            1_000_000 ether
        );
    }
}
