// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title GameItems
/// @notice ERC1155 resources and craftable game items.
contract GameItems is ERC1155, AccessControl , ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant WOOD = 1;
    uint256 public constant IRON = 2;
    uint256 public constant SWORD = 3;

    event Crafted(address indexed player, uint256 indexed itemId, uint256 amount);

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 id, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, "");
    }

    function craftSword() external nonReentrant {
        require(balanceOf(msg.sender, WOOD) >= 10, "Need more wood");

        require(balanceOf(msg.sender, IRON) >= 5, "Need more iron");

        _burn(msg.sender, WOOD, 10);
        _burn(msg.sender, IRON, 5);

        _mint(msg.sender, SWORD, 1, "");

        emit Crafted(msg.sender, SWORD, 1);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
