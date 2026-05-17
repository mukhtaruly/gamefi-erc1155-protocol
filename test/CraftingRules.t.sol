// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {CraftingRules} from "../src/CraftingRules.sol";

contract CraftingRulesTest is Test {
    CraftingRules rules;

    function setUp() public {
        rules = new CraftingRules();
    }

    function testInitializeAndSetRecipe() public {
        rules.initialize(address(this));
        rules.setRecipeCost(3, 1, 10);

        assertEq(rules.recipeCost(3, 1), 10);
        assertEq(rules.version(), 1);
    }

    function testInitializeRejectsZeroAdmin() public {
        vm.expectRevert(CraftingRules.InvalidAdmin.selector);
        rules.initialize(address(0));
    }

    function testInitializeOnlyOnce() public {
        rules.initialize(address(this));

        vm.expectRevert(CraftingRules.AlreadyInitialized.selector);
        rules.initialize(address(this));
    }
}
