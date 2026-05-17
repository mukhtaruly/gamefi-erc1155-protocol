// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {CraftingRules} from "../src/CraftingRules.sol";
import {MockERC20} from "../src/MockERC20.sol";
import {ProtocolFactory} from "../src/ProtocolFactory.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";

contract ProtocolFactoryTest is Test {
    ProtocolFactory factory;
    MockERC20 tokenA;
    MockERC20 tokenB;

    function setUp() public {
        factory = new ProtocolFactory(address(this));
        tokenA = new MockERC20("Gold", "GLD");
        tokenB = new MockERC20("Mana", "MANA");
    }

    function testPredictAndDeployAMMWithCreate2() public {
        bytes32 salt = keccak256("GLD-MANA");
        address predicted = factory.predictAMM(address(tokenA), address(tokenB), salt);

        ResourceAMM amm = factory.deployAMM(address(tokenA), address(tokenB), salt);

        assertEq(address(amm), predicted);
        assertEq(address(amm.tokenA()), address(tokenA));
        assertEq(address(amm.tokenB()), address(tokenB));
    }

    function testDeployCraftingRulesProxy() public {
        address proxy = factory.deployCraftingRulesProxy(keccak256("CRAFTING"), address(this));
        CraftingRules rules = CraftingRules(proxy);

        rules.setRecipeCost(3, 1, 10);

        assertEq(rules.recipeCost(3, 1), 10);
        assertEq(rules.version(), 1);
    }
}
