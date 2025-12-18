// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {OracleVerifier} from "../../src/oracle/OracleVerifier.sol";

/**
 * @title OracleVerifierTest
 * @notice Unit tests for OracleVerifier contract
 */
contract OracleVerifierTest is Test {
    // ============ Constants ============

    bytes32 constant ETH_USD_FEED = keccak256("ETH/USD");
    bytes32 constant BTC_USD_FEED = keccak256("BTC/USD");
    bytes32 constant MNT_USD_FEED = keccak256("MNT/USD");

    uint256 constant PRICE_FRESHNESS_THRESHOLD = 60 seconds;
    uint256 constant VOLATILITY_THRESHOLD = 500; // 5%

    // ============ State ============

    OracleVerifier oracle;

    // ============ Setup ============

    function setUp() public {
        oracle = new OracleVerifier();
    }

    // ============ Tests ============

    /**
     * @notice Test getting price
     */
    function test_GetPrice() public {
        uint256 ethPrice = 2000e8; // $2000

        oracle.setMockPrice(ETH_USD_FEED, ethPrice);

        uint256 retrievedPrice = oracle.getPrice(ETH_USD_FEED);
        assertEq(retrievedPrice, ethPrice, "Price should match");
    }

    /**
     * @notice Test price not available
     */
    function test_GetPriceNotAvailable() public {
        vm.expectRevert("Price not available");
        oracle.getPrice(ETH_USD_FEED);
    }

    /**
     * @notice Test volatility calculation
     */
    function test_GetVolatility() public {
        uint256 volatility = 300; // 3%

        oracle.setMockVolatility(ETH_USD_FEED, volatility);

        uint256 retrievedVolatility = oracle.getVolatility(ETH_USD_FEED);
        assertEq(retrievedVolatility, volatility, "Volatility should match");
    }

    /**
     * @notice Test volatility acceptable - all below threshold
     */
    function test_VolatilityAcceptable_AllBelowThreshold() public {
        uint256[] memory volatilities = new uint256[](3);
        volatilities[0] = 300; // 3%
        volatilities[1] = 400; // 4%
        volatilities[2] = 200; // 2%

        bool acceptable = oracle.isVolatilityAcceptable(volatilities);
        assertTrue(acceptable, "Volatility should be acceptable");
    }

    /**
     * @notice Test volatility acceptable - one at threshold
     */
    function test_VolatilityAcceptable_OneAtThreshold() public {
        uint256[] memory volatilities = new uint256[](3);
        volatilities[0] = 300; // 3%
        volatilities[1] = 500; // 5% - at threshold
        volatilities[2] = 200; // 2%

        bool acceptable = oracle.isVolatilityAcceptable(volatilities);
        assertFalse(acceptable, "Volatility should not be acceptable at threshold");
    }

    /**
     * @notice Test volatility not acceptable - one above threshold
     */
    function test_VolatilityNotAcceptable_OneAboveThreshold() public {
        uint256[] memory volatilities = new uint256[](3);
        volatilities[0] = 300; // 3%
        volatilities[1] = 600; // 6% - above threshold
        volatilities[2] = 200; // 2%

        bool acceptable = oracle.isVolatilityAcceptable(volatilities);
        assertFalse(acceptable, "Volatility should not be acceptable");
    }

    /**
     * @notice Test price freshness - fresh price
     */
    function test_PriceFresh_Fresh() public {
        uint256 ethPrice = 2000e8;

        oracle.setMockPrice(ETH_USD_FEED, ethPrice);

        bool fresh = oracle.isPriceFresh(ETH_USD_FEED);
        assertTrue(fresh, "Price should be fresh");
    }

    /**
     * @notice Test price freshness - stale price
     */
    function test_PriceFresh_Stale() public {
        uint256 ethPrice = 2000e8;
        // Set price to 61 seconds ago
        uint256 staleTimestamp = 1;
        oracle.setMockPriceWithTimestamp(ETH_USD_FEED, ethPrice, staleTimestamp);

        // Warp time forward to make it stale
        vm.warp(block.timestamp + 62 seconds);

        bool fresh = oracle.isPriceFresh(ETH_USD_FEED);
        assertFalse(fresh, "Price should be stale");
    }

    /**
     * @notice Test price freshness - exactly at threshold
     */
    function test_PriceFresh_AtThreshold() public {
        uint256 ethPrice = 2000e8;
        uint256 thresholdTimestamp = block.timestamp > 60 seconds ? block.timestamp - 60 seconds : 1;

        oracle.setMockPriceWithTimestamp(ETH_USD_FEED, ethPrice, thresholdTimestamp);

        bool fresh = oracle.isPriceFresh(ETH_USD_FEED);
        assertTrue(fresh, "Price at threshold should be fresh");
    }

    /**
     * @notice Test multiple price feeds
     */
    function test_MultiplePriceFeeds() public {
        uint256 ethPrice = 2000e8;
        uint256 btcPrice = 40000e8;
        uint256 mntPrice = 1e8;

        oracle.setMockPrice(ETH_USD_FEED, ethPrice);
        oracle.setMockPrice(BTC_USD_FEED, btcPrice);
        oracle.setMockPrice(MNT_USD_FEED, mntPrice);

        assertEq(oracle.getPrice(ETH_USD_FEED), ethPrice);
        assertEq(oracle.getPrice(BTC_USD_FEED), btcPrice);
        assertEq(oracle.getPrice(MNT_USD_FEED), mntPrice);
    }

    /**
     * @notice Test volatility check with multiple feeds
     */
    function test_VolatilityCheckMultipleFeeds() public {
        oracle.setMockVolatility(ETH_USD_FEED, 300);
        oracle.setMockVolatility(BTC_USD_FEED, 400);
        oracle.setMockVolatility(MNT_USD_FEED, 200);

        uint256[] memory volatilities = new uint256[](3);
        volatilities[0] = oracle.getVolatility(ETH_USD_FEED);
        volatilities[1] = oracle.getVolatility(BTC_USD_FEED);
        volatilities[2] = oracle.getVolatility(MNT_USD_FEED);

        bool acceptable = oracle.isVolatilityAcceptable(volatilities);
        assertTrue(acceptable, "All volatilities should be acceptable");
    }
}
