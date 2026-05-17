// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {GameItems} from "./GameItems.sol";

interface IVRFCoordinatorV2Plus {
    struct RandomWordsRequest {
        bytes32 keyHash;
        uint256 subId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        bytes extraArgs;
    }

    function requestRandomWords(RandomWordsRequest calldata req) external returns (uint256 requestId);
}

/// @title VRFLootChest
/// @notice Chainlink VRF-compatible loot chest minter.
contract VRFLootChest is AccessControl, ReentrancyGuard {
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    GameItems public immutable gameItems;
    IVRFCoordinatorV2Plus public immutable coordinator;

    bytes32 public keyHash;
    uint256 public subscriptionId;
    uint16 public requestConfirmations;
    uint32 public callbackGasLimit;

    mapping(uint256 requestId => address opener) public requestOwner;

    event ChestOpened(address indexed player, uint256 indexed requestId);
    event LootMinted(address indexed player, uint256 indexed requestId, uint256 indexed itemId, uint256 amount);
    event VRFConfigUpdated(bytes32 keyHash, uint256 subscriptionId, uint16 confirmations, uint32 callbackGasLimit);

    error OnlyCoordinator();
    error UnknownRequest();

    constructor(
        GameItems gameItems_,
        IVRFCoordinatorV2Plus coordinator_,
        bytes32 keyHash_,
        uint256 subscriptionId_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_
    ) {
        gameItems = gameItems_;
        coordinator = coordinator_;
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        requestConfirmations = requestConfirmations_;
        callbackGasLimit = callbackGasLimit_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONFIG_ROLE, msg.sender);
    }

    function openChest() external nonReentrant returns (uint256 requestId) {
        IVRFCoordinatorV2Plus.RandomWordsRequest memory req = IVRFCoordinatorV2Plus.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: 1,
            extraArgs: ""
        });

        // slither-disable-next-line reentrancy-benign
        requestId = coordinator.requestRandomWords(req);
        requestOwner[requestId] = msg.sender;

        emit ChestOpened(msg.sender, requestId);
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
        if (msg.sender != address(coordinator)) {
            revert OnlyCoordinator();
        }

        address player = requestOwner[requestId];

        if (player == address(0)) {
            revert UnknownRequest();
        }

        delete requestOwner[requestId];

        uint256 roll = randomWords[0] % 100;
        uint256 itemId = roll < 50 ? gameItems.WOOD() : roll < 85 ? gameItems.IRON() : gameItems.SWORD();
        uint256 amount = itemId == gameItems.SWORD() ? 1 : 10;

        emit LootMinted(player, requestId, itemId, amount);

        gameItems.mint(player, itemId, amount);
    }

    function setVRFConfig(
        bytes32 keyHash_,
        uint256 subscriptionId_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_
    ) external onlyRole(CONFIG_ROLE) {
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        requestConfirmations = requestConfirmations_;
        callbackGasLimit = callbackGasLimit_;

        emit VRFConfigUpdated(keyHash_, subscriptionId_, requestConfirmations_, callbackGasLimit_);
    }
}
