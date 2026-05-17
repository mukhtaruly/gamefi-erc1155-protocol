// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {GameItems} from "../src/GameItems.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {RentalVault} from "../src/RentalVault.sol";

contract RentalVaultTest is Test, ERC1155Holder {
    MockERC20 payment;
    GameItems items;
    RentalVault vault;

    address player = address(1);

    function setUp() public {
        payment = new MockERC20("Game Token", "GTK");
        items = new GameItems();
        vault = new RentalVault(payment, items);

        items.mint(address(this), items.SWORD(), 1);
        items.setApprovalForAll(address(vault), true);
        vault.depositRentalItem(items.SWORD(), 1);

        payment.transfer(player, 100 ether);

        vm.startPrank(player);
        payment.approve(address(vault), type(uint256).max);
        items.setApprovalForAll(address(vault), true);
        vm.stopPrank();
    }

    function testVaultDepositAndRentReturn() public {
        payment.approve(address(vault), type(uint256).max);
        vault.deposit(50 ether, address(this));

        assertEq(vault.totalAssets(), 50 ether);

        vm.startPrank(player);
        vault.rent(items.SWORD(), 1, 1 days, 5 ether);

        assertEq(items.balanceOf(player, items.SWORD()), 1);

        vault.returnRental();
        vm.stopPrank();

        assertEq(items.balanceOf(address(vault), items.SWORD()), 1);
        assertEq(vault.totalAssets(), 55 ether);
    }

    function testRejectsInvalidRentalInputsAndMissingRentalReturn() public {
        uint256 sword = items.SWORD();

        vm.expectRevert(RentalVault.InvalidAmount.selector);
        vault.depositRentalItem(sword, 0);

        vm.expectRevert(RentalVault.InvalidAmount.selector);
        vm.prank(player);
        vault.rent(sword, 1, 0, 5 ether);

        vm.expectRevert(RentalVault.RentalExpired.selector);
        vm.prank(player);
        vault.returnRental();
    }

    function testRejectsSecondActiveRental() public {
        uint256 sword = items.SWORD();

        vm.startPrank(player);
        vault.rent(sword, 1, 1 days, 5 ether);

        vm.expectRevert(RentalVault.RentalActive.selector);
        vault.rent(sword, 1, 1 days, 5 ether);
        vm.stopPrank();
    }
}
