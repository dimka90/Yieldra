// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";

/**
 * @title ProtocolAdapter
 * @notice Abstract base class for protocol adapters
 * @dev Provides common functionality for interacting with yield protocols
 */
abstract contract ProtocolAdapter is IProtocolAdapter {
    using SafeERC20 for IERC20;

    // ============ State Variables ============

    address public immutable usdc;
    address public immutable yieldAsset;
    address public vault;

    // ============ Constructor ============

    constructor(address _usdc, address _yieldAsset) {
        require(_usdc != address(0), "Invalid USDC address");
        require(_yieldAsset != address(0), "Invalid yield asset address");
        usdc = _usdc;
        yieldAsset = _yieldAsset;
    }

    // ============ Modifiers ============

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault can call this");
        _;
    }

    // ============ Setup ============

    function setVault(address _vault) external {
        require(_vault != address(0), "Invalid vault address");
        require(vault == address(0), "Vault already set");
        vault = _vault;
    }

    // ============ IProtocolAdapter Implementation ============

    function getYieldAsset() external view override returns (address) {
        return yieldAsset;
    }

    // ============ Internal Helpers ============

    /**
     * @notice Approve token spending
     * @param token Token to approve
     * @param spender Spender address
     * @param amount Amount to approve
     */
    function _approve(address token, address spender, uint256 amount) internal {
        IERC20(token).forceApprove(spender, amount);
    }

    /**
     * @notice Transfer token from sender to recipient
     * @param token Token to transfer
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _transferFrom(address token, address from, address to, uint256 amount) internal {
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    /**
     * @notice Transfer token to recipient
     * @param token Token to transfer
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _transfer(address token, address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Get token balance
     * @param token Token address
     * @param account Account address
     * @return Balance of token
     */
    function _balanceOf(address token, address account) internal view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}
