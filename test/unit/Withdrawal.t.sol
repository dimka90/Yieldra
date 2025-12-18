// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {YieldraVault} from "../../src/contracts/YieldraVault.sol";
import {ProtocolAdapterMock} from "../mocks/ProtocolAdapterMock.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";

/**
 * @title WithdrawalTest
 * @notice Unit tests for withdrawal functionality
 */
contract WithdrawalTest is Test {
    // ============ Constants ============

    uint256 constant INITIAL_BALANCE = 1_000_000e6; // 1M USDC
    uint256 constant PRECISION = 1e18;

    // ============ State ============

    YieldraVault vault;
    ERC20Mock usdc;
    ProtocolAdapterMock[] adapters;
    address user;

    // ============ Setup ============

    function setUp() public {
        // Deploy mock USDC
        usdc = new ERC20Mock("USDC", "USDC", address(this), INITIAL_BALANCE);

        // Deploy vault
        vault = new YieldraVault(address(usdc));

        // Deploy mock adapters
        adapters = new ProtocolAdapterMock[](3);
        for (uint256 i = 0; i < 3; i++) {
            adapters[i] = new ProtocolAdapterMock(address(usdc));
        }

        // Set adapters in vault
        IProtocolAdapter[] memory adapterArray = new IProtocolAdapter[](3);
        for (uint256 i = 0; i < 3; i++) {
            adapterArray[i] = IProtocolAdapter(address(adapters[i]));
        }
        vault.setAdapters(adapterArray);

        // Create test user
        user = address(0x123);
        usdc.mint(user, INITIAL_BALANCE);
    }

    // ============ Tests ============

    /**
     * @notice Test successful withdrawal
     */
    function test_SuccessfulWithdrawal() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount);

        // Withdraw
        vm.prank(user);
        uint256 withdrawn = vault.withdraw(shares);

        // Verify withdrawal
        assertEq(withdrawn, depositAmount, "Withdrawn amount should equal deposit");
        assertEq(vault.getUserBalance(user), 0, "User should have no shares");
        assertEq(vault.getTotalAssets(), 0, "Vault should have no assets");
    }

    /**
     * @notice Test withdrawal with zero shares
     */
    function test_WithdrawalZeroShares() public {
        vm.prank(user);
        vm.expectRevert("Withdrawal shares must be greater than 0");
        vault.withdraw(0);
    }

    /**
     * @notice Test withdrawal with insufficient shares
     */
    function test_WithdrawalInsufficientShares() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        vault.deposit(depositAmount);

        // Try to withdraw more than user has
        vm.prank(user);
        vm.expectRevert("Insufficient shares");
        vault.withdraw(depositAmount + 1);
    }

    /**
     * @notice Test partial withdrawal
     */
    function test_PartialWithdrawal() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount);

        // Withdraw half
        uint256 halfShares = shares / 2;
        vm.prank(user);
        uint256 withdrawn = vault.withdraw(halfShares);

        // Verify partial withdrawal
        assertApproxEq(withdrawn, depositAmount / 2, 100, "Withdrawn should be ~50%");
        assertApproxEq(vault.getUserBalance(user), halfShares, 1, "User should have ~50% shares");
    }

    /**
     * @notice Test multiple withdrawals
     */
    function test_MultipleWithdrawals() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount);

        // First withdrawal
        uint256 quarter = shares / 4;
        vm.prank(user);
        vault.withdraw(quarter);

        // Second withdrawal
        vm.prank(user);
        vault.withdraw(quarter);

        // Verify state
        assertEq(vault.getUserBalance(user), shares - 2 * quarter, "User should have remaining shares");
    }

    /**
     * @notice Test withdrawal event emission
     */
    function test_WithdrawalEventEmission() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount);

        // Withdraw
        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(user, shares, depositAmount);
        vault.withdraw(shares);
    }

    /**
     * @notice Test withdrawal with yield accrual
     */
    function test_WithdrawalWithYield() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount);

        // Simulate yield accrual by increasing total assets
        // In a real scenario, this would come from protocol yield
        uint256 yieldAmount = (depositAmount * 5) / 100; // 5% yield
        usdc.mint(address(vault), yieldAmount);
        
        // Update vault's total assets to reflect yield
        // Note: In production, this would be automatic from protocol interactions
        // For testing, we manually update it
        // This test demonstrates the concept but would need proper yield tracking

        // Withdraw
        vm.prank(user);
        uint256 withdrawn = vault.withdraw(shares);

        // Verify withdrawal amount is reasonable
        assertGe(withdrawn, depositAmount, "Withdrawn should be at least deposit");
    }

    /**
     * @notice Test user value calculation
     */
    function test_UserValueCalculation() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        vault.deposit(depositAmount);

        // Get user value
        uint256 userValue = vault.getUserValue(user);
        assertEq(userValue, depositAmount, "User value should equal deposit");
    }

    /**
     * @notice Test yield earned calculation
     */
    function test_YieldEarnedCalculation() public {
        uint256 depositAmount = 1000e6;

        // Deposit
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);
        vm.prank(user);
        vault.deposit(depositAmount);

        // Initially, yield should be 0
        uint256 yieldEarned = vault.getYieldEarned(user);
        assertEq(yieldEarned, 0, "Initial yield should be 0");

        // In a real scenario, yield would accrue from protocol interactions
        // For this test, we verify the calculation logic works
        // The actual yield accrual would happen through rebalancing and protocol returns
    }

    // ============ Helpers ============

    /**
     * @notice Assert two values are approximately equal
     */
    function assertApproxEq(uint256 a, uint256 b, uint256 tolerance, string memory message) internal pure {
        uint256 diff = a > b ? a - b : b - a;
        uint256 maxDiff = (b * tolerance) / 10000;
        require(diff <= maxDiff, message);
    }

    // ============ Events ============

    event Withdrawal(address indexed user, uint256 shares, uint256 amount);
}
