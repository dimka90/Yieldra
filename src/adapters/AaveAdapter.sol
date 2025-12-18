// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ProtocolAdapter} from "../abstracts/ProtocolAdapter.sol";

/**
 * @title AaveAdapter
 * @notice Adapter for Aave V3 (aUSDC) protocol
 * @dev Handles deposits and withdrawals from Aave V3
 */
contract AaveAdapter is ProtocolAdapter {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    // Aave V3 contract addresses (Mantle)
    address constant AAVE_AUSDC = 0x0000000000000000000000000000000000000000; // TODO: Update with actual address
    address constant AAVE_POOL = 0x0000000000000000000000000000000000000000; // TODO: Update with actual address

    // ============ Constructor ============

    constructor(address _usdc) ProtocolAdapter(_usdc, AAVE_AUSDC) {}

    // ============ IProtocolAdapter Implementation ============

    /**
     * @notice Deposit USDC into Aave V3
     * @param amount Amount of USDC to deposit
     * @return received Amount of aUSDC received
     */
    function deposit(uint256 amount) external override onlyVault returns (uint256 received) {
        require(amount > 0, "Deposit amount must be greater than 0");

        // Approve USDC to Aave pool
        _approve(usdc, AAVE_POOL, amount);

        // Call Aave deposit function
        // This is a simplified version - actual implementation depends on Aave's interface
        // For now, we'll assume 1:1 conversion
        IERC20(usdc).safeTransferFrom(vault, address(this), amount);
        
        // In real implementation, call Aave's deposit function
        // ILendingPool(AAVE_POOL).deposit(usdc, amount, address(this), 0);
        
        // For testing, assume 1:1 conversion
        received = amount;

        return received;
    }

    /**
     * @notice Withdraw from Aave V3
     * @param amount Amount of aUSDC to withdraw
     * @return received Amount of USDC received
     */
    function withdraw(uint256 amount) external override onlyVault returns (uint256 received) {
        require(amount > 0, "Withdraw amount must be greater than 0");

        uint256 ausdcBalance = IERC20(yieldAsset).balanceOf(address(this));
        require(ausdcBalance >= amount, "Insufficient aUSDC balance");

        // Call Aave withdraw function
        // This is a simplified version - actual implementation depends on Aave's interface
        // For now, we'll assume 1:1 conversion
        
        // In real implementation, call Aave's withdraw function
        // ILendingPool(AAVE_POOL).withdraw(usdc, amount, address(this));
        
        // For testing, assume 1:1 conversion
        received = amount;

        // Transfer USDC back to vault
        IERC20(usdc).safeTransfer(vault, received);

        return received;
    }

    /**
     * @notice Get current balance of aUSDC held by vault
     * @return Balance of aUSDC
     */
    function balance() external view override returns (uint256) {
        return IERC20(yieldAsset).balanceOf(address(this));
    }

    /**
     * @notice Get current APY of Aave V3
     * @return APY in basis points (e.g., 500 = 5%)
     */
    function getAPY() external view override returns (uint256) {
        // In real implementation, fetch from Aave's contract
        // For now, return a fixed value
        return 350; // 3.5% APY
    }
}
