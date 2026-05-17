// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameTreasury} from "../src/GameTreasury.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract GameTreasuryTest is Test {
    MockERC20 token;
    GameTreasury treasury;

    address player = address(1);

    function setUp() public {
        token = new MockERC20("Gold", "GLD");
        treasury = new GameTreasury(address(this));

        token.transfer(player, 100 ether);

        vm.prank(player);
        token.approve(address(treasury), type(uint256).max);
    }

    function testDepositAndWithdrawAccounting() public {
        vm.prank(player);
        treasury.deposit(token, 25 ether);

        assertEq(treasury.accountedBalance(address(token)), 25 ether);
        assertEq(token.balanceOf(address(treasury)), 25 ether);

        treasury.assertAccounting(token);
        treasury.withdraw(token, player, 10 ether);

        assertEq(treasury.accountedBalance(address(token)), 15 ether);
        assertEq(token.balanceOf(address(treasury)), 15 ether);
    }

    function testRejectsZeroDepositAndWithdraw() public {
        vm.prank(player);
        vm.expectRevert(GameTreasury.InvalidAmount.selector);
        treasury.deposit(token, 0);

        vm.expectRevert(GameTreasury.InvalidAmount.selector);
        treasury.withdraw(token, player, 0);
    }

    function testDetectsAccountingMismatch() public {
        token.transfer(address(treasury), 1 ether);

        vm.expectRevert();
        treasury.assertAccounting(token);
    }
}
