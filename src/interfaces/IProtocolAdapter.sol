// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IProtocolAdapter
 * @notice Interface for protocol adapters (Ondo, Ethena, Aave)
 * @dev Defines standard interface for interacting with yield protocols
 */
interface IProtocolAdapter {
    /**
     * @notice Deposit USDC into the protocol
     * @param amount Amount of USDC to deposit
     * @return received Amount of yield asset received
     */
    function deposit(uint256 amount) external returns (uint256 received);

    /**
     * @notice Withdraw from the protocol
     * @param amount Amount of yield asset to withdraw
     * @return received Amount of USDC received
     */
    function withdraw(uint256 amount) external returns (uint256 received);

    /**
     * @notice Get current balance of yield asset held by vault
     * @return Balance of yield asset
     */
    function balance() external view returns (uint256);

    /**
     * @notice Get current APY of the protocol
     * @return APY in basis points (e.g., 500 = 5%)
     */
    function getAPY() external view returns (uint256);

    /**
     * @notice Get the yield asset address
     * @return Address of the yield asset token
     */
    function getYieldAsset() external view returns (address);
}
