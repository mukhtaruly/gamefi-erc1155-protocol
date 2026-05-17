// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameItems} from "../src/GameItems.sol";
import {GameToken} from "../src/GameToken.sol";
import {ProtocolFactory} from "../src/ProtocolFactory.sol";

contract ForkDeploymentTest is Test {
    function testFork_BaseSepoliaDeploymentShape() public {
        string memory rpcUrl = vm.envOr("BASE_SEPOLIA_RPC_URL", string(""));

        if (bytes(rpcUrl).length == 0) {
            return;
        }

        vm.createSelectFork(rpcUrl);

        GameToken token = new GameToken();
        GameItems items = new GameItems();
        ProtocolFactory factory = new ProtocolFactory(address(this));

        assertEq(token.name(), "Game Token");
        assertTrue(items.hasRole(items.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(factory.hasRole(factory.DEPLOYER_ROLE(), address(this)));
    }
}
