// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {LPToken} from "./LPToken.sol";

contract ResourceAMM is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    LPToken public immutable lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    error InsufficientOutput();
    error InvalidLiquidity();
    error InvalidAmount();
    error InvalidRatio();
    error InvariantViolation();

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swapped(
        address indexed trader, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);

        lpToken = new LPToken();
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant {
        if (amountA == 0 || amountB == 0) {
            revert InvalidAmount();
        }

        uint256 liquidity;
        uint256 totalSupply = lpToken.totalSupply();

        if (totalSupply == 0) {
            liquidity = amountA;
        } else {
            if (amountA * reserveB != amountB * reserveA) {
                revert InvalidRatio();
            }

            liquidity = (amountA * totalSupply) / reserveA;
        }

        if (liquidity == 0) {
            revert InvalidLiquidity();
        }

        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        lpToken.mint(msg.sender, liquidity);

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external nonReentrant {
        uint256 totalSupply = lpToken.totalSupply();

        if (liquidity == 0 || totalSupply == 0) {
            revert InvalidLiquidity();
        }

        uint256 amountA = (reserveA * liquidity) / totalSupply;

        uint256 amountB = (reserveB * liquidity) / totalSupply;

        reserveA -= amountA;
        reserveB -= amountB;

        lpToken.burn(msg.sender, liquidity);

        tokenA.safeTransfer(msg.sender, amountA);

        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    function swapAForB(uint256 amountIn, uint256 minAmountOut) external nonReentrant returns (uint256 amountOut) {
        uint256 oldK = reserveA * reserveB;
        amountOut = _getAmountOut(amountIn, reserveA, reserveB);

        if (amountOut < minAmountOut) {
            revert InsufficientOutput();
        }

        tokenA.safeTransferFrom(msg.sender, address(this), amountIn);

        reserveA += amountIn;
        reserveB -= amountOut;

        if (reserveA * reserveB < oldK) {
            revert InvariantViolation();
        }

        tokenB.safeTransfer(msg.sender, amountOut);

        emit Swapped(msg.sender, address(tokenA), address(tokenB), amountIn, amountOut);
    }

    function swapBForA(uint256 amountIn, uint256 minAmountOut) external nonReentrant returns (uint256 amountOut) {
        uint256 oldK = reserveA * reserveB;
        amountOut = _getAmountOut(amountIn, reserveB, reserveA);

        if (amountOut < minAmountOut) {
            revert InsufficientOutput();
        }

        tokenB.safeTransferFrom(msg.sender, address(this), amountIn);

        reserveB += amountIn;
        reserveA -= amountOut;

        if (reserveA * reserveB < oldK) {
            revert InvariantViolation();
        }

        tokenA.safeTransfer(msg.sender, amountOut);

        emit Swapped(msg.sender, address(tokenB), address(tokenA), amountIn, amountOut);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256) {
        return _getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getK() external view returns (uint256) {
        return reserveA * reserveB;
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        if (amountIn == 0) {
            revert InvalidAmount();
        }

        if (reserveIn == 0 || reserveOut == 0) {
            revert InvalidLiquidity();
        }

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;

        return (reserveOut * amountInWithFee) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }
}
