// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title CraftingRules
/// @notice UUPS-upgradeable protocol configuration for crafting recipes.
contract CraftingRules is AccessControl, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    bool private _initialized;

    mapping(uint256 itemId => mapping(uint256 resourceId => uint256 amount)) public recipeCost;

    event Initialized(address indexed admin);
    event RecipeCostSet(uint256 indexed itemId, uint256 indexed resourceId, uint256 amount);

    error AlreadyInitialized();
    error InvalidAdmin();

    function initialize(address admin) external {
        if (_initialized) {
            revert AlreadyInitialized();
        }

        if (admin == address(0)) {
            revert InvalidAdmin();
        }

        _initialized = true;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(CONFIG_ROLE, admin);

        emit Initialized(admin);
    }

    function setRecipeCost(uint256 itemId, uint256 resourceId, uint256 amount) external onlyRole(CONFIG_ROLE) {
        recipeCost[itemId][resourceId] = amount;

        emit RecipeCostSet(itemId, resourceId, amount);
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}
}
