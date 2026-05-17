// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {GameItems} from "../src/GameItems.sol";
import {IVRFCoordinatorV2Plus, VRFLootChest} from "../src/VRFLootChest.sol";

contract MockVRFCoordinator is IVRFCoordinatorV2Plus {
    uint256 public nextRequestId = 1;

    function requestRandomWords(RandomWordsRequest calldata) external returns (uint256 requestId) {
        requestId = nextRequestId++;
    }

    function fulfill(VRFLootChest chest, uint256 requestId, uint256 randomWord) external {
        uint256[] memory words = new uint256[](1);
        words[0] = randomWord;
        chest.rawFulfillRandomWords(requestId, words);
    }
}

contract VRFLootChestTest is Test {
    GameItems items;
    MockVRFCoordinator coordinator;
    VRFLootChest chest;

    address player = address(1);

    function setUp() public {
        items = new GameItems();
        coordinator = new MockVRFCoordinator();
        chest = new VRFLootChest(items, coordinator, bytes32(uint256(1)), 1, 3, 200_000);

        items.grantRole(items.MINTER_ROLE(), address(chest));
    }

    function testOpenChestAndMintLoot() public {
        vm.prank(player);
        uint256 requestId = chest.openChest();

        coordinator.fulfill(chest, requestId, 90);

        assertEq(items.balanceOf(player, items.SWORD()), 1);
        assertEq(chest.requestOwner(requestId), address(0));
    }

    function testMintWoodAndIronLoot() public {
        vm.prank(player);
        uint256 woodRequest = chest.openChest();
        coordinator.fulfill(chest, woodRequest, 10);

        vm.prank(player);
        uint256 ironRequest = chest.openChest();
        coordinator.fulfill(chest, ironRequest, 60);

        assertEq(items.balanceOf(player, items.WOOD()), 10);
        assertEq(items.balanceOf(player, items.IRON()), 10);
    }

    function testOnlyCoordinatorCanFulfillAndConfigCanUpdate() public {
        vm.prank(player);
        uint256 requestId = chest.openChest();

        uint256[] memory words = new uint256[](1);
        words[0] = 1;

        vm.expectRevert(VRFLootChest.OnlyCoordinator.selector);
        chest.rawFulfillRandomWords(requestId, words);

        chest.setVRFConfig(bytes32(uint256(2)), 2, 5, 300_000);

        assertEq(chest.keyHash(), bytes32(uint256(2)));
        assertEq(chest.subscriptionId(), 2);
        assertEq(chest.requestConfirmations(), 5);
        assertEq(chest.callbackGasLimit(), 300_000);
    }

    function testRejectsUnknownRequest() public {
        vm.expectRevert(VRFLootChest.UnknownRequest.selector);
        coordinator.fulfill(chest, 999, 1);
    }
}
