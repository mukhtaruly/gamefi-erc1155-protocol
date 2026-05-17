// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GameItems} from "../src/GameItems.sol";

contract GameItemsTest is Test {
    GameItems game;

    address player = address(1);

    function setUp() public {
        game = new GameItems();

        game.mint(player, game.WOOD(), 100);

        game.mint(player, game.IRON(), 100);
    }

    function testCraftSword() public {
        vm.startPrank(player);

        game.craftSword();

        assertEq(game.balanceOf(player, game.SWORD()), 1);

        assertEq(game.balanceOf(player, game.WOOD()), 90);

        assertEq(game.balanceOf(player, game.IRON()), 95);

        vm.stopPrank();
    }

    function testCraftSwordRequiresResources() public {
        address emptyPlayer = address(2);

        vm.prank(emptyPlayer);
        vm.expectRevert(bytes("Need more wood"));
        game.craftSword();
    }

    function testSupportsAccessControlInterface() public view {
        assertTrue(game.supportsInterface(type(IERC165).interfaceId));
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
