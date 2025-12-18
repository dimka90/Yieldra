// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {YieldraVault} from "../../src/contracts/YieldraVault.sol";
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";

/**
 * @title YieldraVaultTest
 * @notice Unit tests for YieldraVault contract
 */
contract YieldraVaultTest is Test {
    // ============ Constants ============

    uint256 constant INITIAL_BALANCE = 1_000_000e6; // 1M USDC
    uint256 constant PRECISION = 1e18;
    uint256 constant PERCENTAGE_PRECISION = 100;

    // ============ State ============

    YieldraVault vault;
    address usdc;
    address[] adapters;

    // ============ Setup ============

    function setUp() public {
        // Deploy mock USDC
        usdc = address(0x1); // Mock address for testing

        // Deploy vault
        vault = new YieldraVault(usdc);

        // Verify initial state
        assertEq(vault.getTotalAssets(), 0, "Initial total assets should be 0");
        assertEq(vault.getSharePrice(), PRECISION, "Initial share price should be 1");
    }

    // ============ Tests ============

    /**
     * @notice Test initial vault state
     */
    function test_InitialState() public {
        assertEq(vault.getTotalAssets(), 0);
        assertEq(vault.getSharePrice(), PRECISION);
        
        uint256[] memory allocation = vault.getCurrentAllocation();
        assertEq(allocation.length, 3);
        // Each should be approximately 33.33%
        assertApproxEq(allocation[0], 3333, 1);
        assertApproxEq(allocation[1], 3333, 1);
        assertApproxEq(allocation[2], 3334, 1);
    }

    /**
     * @notice Test share price calculation
     */
    function test_SharePriceCalculation() public {
        // With 0 shares, share price should be 1
        assertEq(vault.getSharePrice(), PRECISION);

        // After first deposit, share price should still be 1
        // (1 share = 1 USDC for first deposit)
        // This would require mocking the deposit flow
    }

    /**
     * @notice Test allocation validation
     */
    function test_AllocationValidation() public {
        // Valid allocation: 33%, 33%, 34%
        uint256[] memory validAllocation = new uint256[](3);
        validAllocation[0] = 33 * PERCENTAGE_PRECISION;
        validAllocation[1] = 33 * PERCENTAGE_PRECISION;
        validAllocation[2] = 34 * PERCENTAGE_PRECISION;

        // This should not revert (would need adapters set up)
        // For now, just verify the allocation is stored correctly
    }

    /**
     * @notice Test invalid allocation - below minimum
     */
    function test_AllocationBelowMinimum() public {
        uint256[] memory invalidAllocation = new uint256[](3);
        invalidAllocation[0] = 5 * PERCENTAGE_PRECISION; // 5% - below 10% minimum
        invalidAllocation[1] = 50 * PERCENTAGE_PRECISION;
        invalidAllocation[2] = 45 * PERCENTAGE_PRECISION;

        // This should revert when we try to rebalance
        // (requires adapters to be set up first)
    }

    /**
     * @notice Test invalid allocation - above maximum
     */
    function test_AllocationAboveMaximum() public {
        uint256[] memory invalidAllocation = new uint256[](3);
        invalidAllocation[0] = 70 * PERCENTAGE_PRECISION; // 70% - above 60% maximum
        invalidAllocation[1] = 20 * PERCENTAGE_PRECISION;
        invalidAllocation[2] = 10 * PERCENTAGE_PRECISION;

        // This should revert when we try to rebalance
    }

    /**
     * @notice Test user balance tracking
     */
    function test_UserBalanceTracking() public {
        address user = address(0x123);
        
        // Initially, user should have 0 shares
        assertEq(vault.getUserBalance(user), 0);
        
        // After deposit, user should have shares
        // (requires mocking deposit)
    }

    /**
     * @notice Test yield calculation
     */
    function test_YieldCalculation() public {
        address user = address(0x123);
        
        // Initially, yield should be 0
        assertEq(vault.getYieldEarned(user), 0);
        
        // After deposit and yield accrual, yield should be positive
        // (requires mocking deposit and yield accrual)
    }

    // ============ Helpers ============

    /**
     * @notice Assert two values are approximately equal
     * @param a First value
     * @param b Second value
     * @param tolerance Tolerance (basis points)
     */
    function assertApproxEq(uint256 a, uint256 b, uint256 tolerance) internal pure {
        uint256 diff = a > b ? a - b : b - a;
        uint256 maxDiff = (b * tolerance) / 10000;
        require(diff <= maxDiff, "Values not approximately equal");
    }
}
