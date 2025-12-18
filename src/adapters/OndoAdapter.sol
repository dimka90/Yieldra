// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ProtocolAdapter} from "../abstracts/ProtocolAdapter.sol";

/**
 * @title OndoAdapter
 * @notice Adapter for Ondo Finance (USDY) protocol
 * @dev Handles deposits and withdrawals from Ondo Finance
 */
contract OndoAdapter is ProtocolAdapter {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    // Ondo Finance contract addresses (Mantle)
    address constant ONDO_USDY = 0x0000000000000000000000000000000000000000; // TODO: Update with actual address
    address constant ONDO_ROUTER = 0x0000000000000000000000000000000000000000; // TODO: Update with actual address

    // ============ Constructor ============

    constructor(address _usdc) ProtocolAdapter(_usdc, ONDO_USDY) {}

    // ============ IProtocolAdapter Implementation ============

    /**
     * @notice Deposit USDC into Ondo Finance
     * @param amount Amount of USDC to deposit
     * @return received Amount of USDY received
     */
    function deposit(uint256 amount) external override onlyVault returns (uint256 received) {
        require(amount > 0, "Deposit amount must be greater than 0");

        // Approve USDC to Ondo router
        _approve(usdc, ONDO_ROUTER, amount);

        // Call Ondo deposit function
        // This is a simplified version - actual implementation depends on Ondo's interface
        // For now, we'll assume 1:1 conversion
        IERC20(usdc).safeTransferFrom(vault, address(this), amount);
        
        // In real implementation, call Ondo's deposit function
        // received = IOndo(ONDO_ROUTER).deposit(amount);
        
        // For testing, assume 1:1 conversion
        received = amount;

        return received;
    }

    /**
     * @notice Withdraw from Ondo Finance
     * @param amount Amount of USDY to withdraw
     * @return received Amount of USDC received
     */
    function withdraw(uint256 amount) external override onlyVault returns (uint256 received) {
        require(amount > 0, "Withdraw amount must be greater than 0");

        uint256 usdyBalance = IERC20(yieldAsset).balanceOf(address(this));
        require(usdyBalance >= amount, "Insufficient USDY balance");

        // Approve USDY to Ondo router
        _approve(yieldAsset, ONDO_ROUTER, amount);

        // Call Ondo withdraw function
        // This is a simplified version - actual implementation depends on Ondo's interface
        // For now, we'll assume 1:1 conversion
        
        // In real implementation, call Ondo's withdraw function
        // received = IOndo(ONDO_ROUTER).withdraw(amount);
        
        // For testing, assume 1:1 conversion
        received = amount;

        // Transfer USDC back to vault
        IERC20(usdc).safeTransfer(vault, received);

        return received;
    }

    /**
     * @notice Get current balance of USDY held by vault
     * @return Balance of USDY
     */
    function balance() external view override returns (uint256) {
        return IERC20(yieldAsset).balanceOf(address(this));
    }

    /**
     * @notice Get current APY of Ondo Finance
     * @return APY in basis points (e.g., 500 = 5%)
     */
    function getAPY() external view override returns (uint256) {
        // In real implementation, fetch from Ondo's contract
        // For now, return a fixed value
        return 500; // 5% APY
    }
}
