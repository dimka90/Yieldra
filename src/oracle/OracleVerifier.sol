// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IOracleVerifier} from "../interfaces/IOracleVerifier.sol";

/**
 * @title OracleVerifier
 * @notice Verifies oracle prices and volatility using Pyth Network
 * @dev Integrates with Pyth price feeds on Mantle Network
 */
contract OracleVerifier is IOracleVerifier {
    // ============ Constants ============

    uint256 constant PRICE_FRESHNESS_THRESHOLD = 60 seconds;
    uint256 constant VOLATILITY_THRESHOLD = 500; // 5% in basis points
    uint256 constant PRECISION = 1e8; // Pyth uses 8 decimals

    // ============ State Variables ============

    // Mock price data for testing (in production, would use Pyth contract)
    mapping(bytes32 => uint256) public mockPrices;
    mapping(bytes32 => uint256) public mockPriceTimestamps;
    mapping(bytes32 => uint256) public mockVolatilities;

    // ============ Events ============

    event PriceUpdated(bytes32 indexed priceFeed, uint256 price, uint256 timestamp);
    event VolatilityCalculated(bytes32 indexed priceFeed, uint256 volatility);

    // ============ IOracleVerifier Implementation ============

    /**
     * @notice Get current price from Pyth oracle
     * @param priceFeed Pyth price feed ID
     * @return price Current price (scaled by 1e8)
     */
    function getPrice(bytes32 priceFeed) external view override returns (uint256 price) {
        price = mockPrices[priceFeed];
        require(price > 0, "Price not available");
        return price;
    }

    /**
     * @notice Calculate 24-hour volatility for an asset
     * @param priceFeed Pyth price feed ID
     * @return volatility Volatility percentage (e.g., 500 = 5%)
     */
    function getVolatility(bytes32 priceFeed) external view override returns (uint256 volatility) {
        volatility = mockVolatilities[priceFeed];
        return volatility;
    }

    /**
     * @notice Check if volatility is acceptable for rebalancing
     * @param volatilities Array of volatility percentages
     * @return acceptable True if all volatilities are below threshold
     */
    function isVolatilityAcceptable(uint256[] calldata volatilities) external view override returns (bool acceptable) {
        for (uint256 i = 0; i < volatilities.length; i++) {
            if (volatilities[i] >= VOLATILITY_THRESHOLD) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Check if price feed is fresh (not stale)
     * @param priceFeed Pyth price feed ID
     * @return fresh True if price is less than 60 seconds old
     */
    function isPriceFresh(bytes32 priceFeed) external view override returns (bool fresh) {
        uint256 timestamp = mockPriceTimestamps[priceFeed];
        require(timestamp > 0, "Price timestamp not set");
        
        uint256 age = block.timestamp - timestamp;
        return age <= PRICE_FRESHNESS_THRESHOLD;
    }

    // ============ Test Helpers ============

    /**
     * @notice Set mock price for testing
     * @param priceFeed Price feed ID
     * @param price Price value
     */
    function setMockPrice(bytes32 priceFeed, uint256 price) external {
        mockPrices[priceFeed] = price;
        mockPriceTimestamps[priceFeed] = block.timestamp;
        emit PriceUpdated(priceFeed, price, block.timestamp);
    }

    /**
     * @notice Set mock price with custom timestamp
     * @param priceFeed Price feed ID
     * @param price Price value
     * @param timestamp Price timestamp
     */
    function setMockPriceWithTimestamp(bytes32 priceFeed, uint256 price, uint256 timestamp) external {
        mockPrices[priceFeed] = price;
        mockPriceTimestamps[priceFeed] = timestamp;
        emit PriceUpdated(priceFeed, price, timestamp);
    }

    /**
     * @notice Set mock volatility for testing
     * @param priceFeed Price feed ID
     * @param volatility Volatility value (basis points)
     */
    function setMockVolatility(bytes32 priceFeed, uint256 volatility) external {
        mockVolatilities[priceFeed] = volatility;
        emit VolatilityCalculated(priceFeed, volatility);
    }

    /**
     * @notice Get mock price timestamp
     * @param priceFeed Price feed ID
     * @return timestamp Price timestamp
     */
    function getMockPriceTimestamp(bytes32 priceFeed) external view returns (uint256 timestamp) {
        return mockPriceTimestamps[priceFeed];
    }
}
