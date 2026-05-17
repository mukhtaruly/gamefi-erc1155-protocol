// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title GameTreasury
/// @notice Token treasury with explicit per-token accounting for DAO-controlled funds.
contract GameTreasury is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    mapping(address token => uint256 amount) public accountedBalance;

    event Deposited(address indexed token, address indexed from, uint256 amount);
    event Withdrawn(address indexed token, address indexed to, uint256 amount);

    error InvalidAmount();
    error AccountingMismatch(address token, uint256 accounted, uint256 actual);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TREASURER_ROLE, admin);
    }

    function deposit(IERC20 token, uint256 amount) external nonReentrant {
        if (amount == 0) {
            revert InvalidAmount();
        }

        accountedBalance[address(token)] += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(address(token), msg.sender, amount);
    }

    function withdraw(IERC20 token, address to, uint256 amount) external onlyRole(TREASURER_ROLE) nonReentrant {
        if (amount == 0) {
            revert InvalidAmount();
        }

        accountedBalance[address(token)] -= amount;
        token.safeTransfer(to, amount);

        emit Withdrawn(address(token), to, amount);
    }

    function assertAccounting(IERC20 token) external view {
        uint256 accounted = accountedBalance[address(token)];
        uint256 actual = token.balanceOf(address(this));

        if (accounted != actual) {
            revert AccountingMismatch(address(token), accounted, actual);
        }
    }
}
