// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IOracleVerifier
 * @notice Interface for oracle price verification using Pyth
 * @dev Handles price feeds and volatility checks
 */
interface IOracleVerifier {
    /**
     * @notice Get current price from Pyth oracle
     * @param priceFeed Pyth price feed ID
     * @return price Current price (scaled by 1e8)
     */
    function getPrice(bytes32 priceFeed) external view returns (uint256 price);

    /**
     * @notice Calculate 24-hour volatility for an asset
     * @param priceFeed Pyth price feed ID
     * @return volatility Volatility percentage (e.g., 500 = 5%)
     */
    function getVolatility(bytes32 priceFeed) external view returns (uint256 volatility);

    /**
     * @notice Check if volatility is acceptable for rebalancing
     * @param volatilities Array of volatility percentages
     * @return acceptable True if all volatilities are below threshold
     */
    function isVolatilityAcceptable(uint256[] calldata volatilities) external view returns (bool acceptable);

    /**
     * @notice Check if price feed is fresh (not stale)
     * @param priceFeed Pyth price feed ID
     * @return fresh True if price is less than 60 seconds old
     */
    function isPriceFresh(bytes32 priceFeed) external view returns (bool fresh);
}
