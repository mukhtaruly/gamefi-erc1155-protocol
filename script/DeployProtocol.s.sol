// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {GameGovernor} from "../src/GameGovernor.sol";
import {GameItems} from "../src/GameItems.sol";
import {GameToken} from "../src/GameToken.sol";
import {GameTreasury} from "../src/GameTreasury.sol";
import {ProtocolFactory} from "../src/ProtocolFactory.sol";
import {RentalVault} from "../src/RentalVault.sol";
import {VRFLootChest, IVRFCoordinatorV2Plus} from "../src/VRFLootChest.sol";
import {ResourceAMM} from "../src/ResourceAMM.sol";

contract DeployProtocol is Script {
    function run() external {
        address deployer =
            vm.envOr("DEPLOYER", msg.sender);

        address vrfCoordinator =
            vm.envOr(
                "VRF_COORDINATOR",
                address(0x0000000000000000000000000000000000000001)
            );

        bytes32 keyHash =
            vm.envOr(
                "VRF_KEY_HASH",
                bytes32(uint256(1))
            );

        uint256 subscriptionId =
            vm.envOr(
                "VRF_SUBSCRIPTION_ID",
                uint256(1)
            );

        vm.startBroadcast();

        GameToken token = new GameToken();
        GameToken resourceToken = new GameToken();
        // ITEMS
        GameItems items = new GameItems();

        items.mint(deployer, 1, 100);
        items.mint(deployer, 2, 100);

        address[] memory proposers =
            new address[](0);

        address[] memory executors =
            new address[](1);

        executors[0] = address(0);

        TimelockController timelock =
            new TimelockController(
                2 days,
                proposers,
                executors,
                deployer
            );

        GameGovernor governor =
            new GameGovernor(
                token,
                timelock
            );

        GameTreasury treasury =
            new GameTreasury(
                address(timelock)
            );

        RentalVault vault =
            new RentalVault(
                token,
                items
            );

        new ProtocolFactory(deployer);

        VRFLootChest lootChest =
            new VRFLootChest(
                items,
                IVRFCoordinatorV2Plus(vrfCoordinator),
                keyHash,
                subscriptionId,
                3,
                200_000
            );

        ResourceAMM amm =
            new ResourceAMM(
                address(token),
                address(resourceToken)
            );

        items.grantRole(
            items.MINTER_ROLE(),
            address(lootChest)
        );

        timelock.grantRole(
            timelock.PROPOSER_ROLE(),
            address(governor)
        );

        timelock.grantRole(
            timelock.CANCELLER_ROLE(),
            address(governor)
        );

        vault.grantRole(
            vault.CURATOR_ROLE(),
            deployer
        );

        token.approve(
            address(amm),
            10000 ether
        );
        resourceToken.approve(
            address(amm),
            10_000 ether
        );

        amm.addLiquidity(
            5000 ether,
            5000 ether
        );

        vm.stopBroadcast();
    }
}