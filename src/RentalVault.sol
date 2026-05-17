// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title RentalVault
/// @notice ERC4626 yield-style vault that also rents escrowed ERC1155 items for ERC20 fees.
contract RentalVault is ERC4626, AccessControl, ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    struct Rental {
        uint256 itemId;
        uint256 amount;
        uint64 expiresAt;
    }

    IERC1155 public immutable gameItems;
    mapping(address user => Rental rental) public rentals;

    event ItemDeposited(address indexed curator, uint256 indexed itemId, uint256 amount);
    event ItemRented(address indexed renter, uint256 indexed itemId, uint256 amount, uint64 expiresAt, uint256 fee);
    event ItemReturned(address indexed renter, uint256 indexed itemId, uint256 amount);

    error InvalidAmount();
    error RentalActive();
    error RentalExpired();

    constructor(IERC20 asset_, IERC1155 gameItems_) ERC20("GameFi Rental Vault", "grGTK") ERC4626(asset_) {
        gameItems = gameItems_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CURATOR_ROLE, msg.sender);
    }

    function depositRentalItem(uint256 itemId, uint256 amount) external onlyRole(CURATOR_ROLE) nonReentrant {
        if (amount == 0) {
            revert InvalidAmount();
        }

        gameItems.safeTransferFrom(msg.sender, address(this), itemId, amount, "");

        emit ItemDeposited(msg.sender, itemId, amount);
    }

    function rent(uint256 itemId, uint256 amount, uint64 duration, uint256 fee) external nonReentrant {
        if (amount == 0 || duration == 0 || fee == 0) {
            revert InvalidAmount();
        }

        // slither-disable-next-line timestamp
        if (rentals[msg.sender].expiresAt >= block.timestamp) {
            revert RentalActive();
        }

        IERC20(asset()).safeTransferFrom(msg.sender, address(this), fee);

        uint64 expiresAt = uint64(block.timestamp + duration);
        rentals[msg.sender] = Rental({itemId: itemId, amount: amount, expiresAt: expiresAt});
        gameItems.safeTransferFrom(address(this), msg.sender, itemId, amount, "");

        emit ItemRented(msg.sender, itemId, amount, expiresAt, fee);
    }

    function returnRental() external nonReentrant {
        Rental memory rental = rentals[msg.sender];

        if (rental.expiresAt == 0) {
            revert RentalExpired();
        }

        delete rentals[msg.sender];
        gameItems.safeTransferFrom(msg.sender, address(this), rental.itemId, rental.amount, "");

        emit ItemReturned(msg.sender, rental.itemId, rental.amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
