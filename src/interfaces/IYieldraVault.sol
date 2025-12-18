// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IYieldraVault
 * @notice Interface for the Yieldra yield optimization vault
 * @dev Defines all external functions and events for the vault
 */
interface IYieldraVault {
    // ============ Events ============

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdrawal(address indexed user, uint256 shares, uint256 amount);
    event Rebalance(uint256[] previousAllocation, uint256[] newAllocation, uint256 timestamp);
    event Error(string reason);

    // ============ Deposit/Withdraw ============

    /**
     * @notice Deposit USDC into the vault
     * @param amount Amount of USDC to deposit
     * @return shares Number of vault shares minted
     */
    function deposit(uint256 amount) external returns (uint256 shares);

    /**
     * @notice Withdraw USDC from the vault
     * @param shares Number of vault shares to burn
     * @return amount Amount of USDC returned to user
     */
    function withdraw(uint256 shares) external returns (uint256 amount);

    // ============ Rebalancing ============

    /**
     * @notice Propose and execute a rebalancing of vault funds
     * @param allocation Target allocation percentages [ondo%, ethena%, aave%]
     * @dev Each allocation must be between 10% and 60%
     * @dev Allocation percentages must sum to 100%
     */
    function rebalance(uint256[] calldata allocation) external;

    // ============ State Queries ============

    /**
     * @notice Get total assets under management in USDC
     * @return Total USDC value of all vault positions
     */
    function totalAssets() external view returns (uint256);



    /**
     * @notice Get user's USDC value (shares × share price)
     * @param user User address
     * @return USDC value of user's shares
     */
    function getUserValue(address user) external view returns (uint256);

    /**
     * @notice Get user's yield earned
     * @param user User address
     * @return Yield earned in USDC
     */
    function getYieldEarned(address user) external view returns (uint256);
}
