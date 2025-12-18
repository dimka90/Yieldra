// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {YieldraVault} from "../../src/contracts/YieldraVault.sol";
import {ProtocolAdapterMock} from "../mocks/ProtocolAdapterMock.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";

/**
 * @title DepositTest
 * @notice Unit tests for deposit functionality
 */
contract DepositTest is Test {
    // ============ Constants ============

    uint256 constant INITIAL_BALANCE = 1_000_000e6; // 1M USDC
    uint256 constant PRECISION = 1e18;
    uint256 constant PERCENTAGE_PRECISION = 100;

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
     * @notice Test successful deposit
     */
    function test_SuccessfulDeposit() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Approve vault to spend USDC
        vm.prank(user);
        usdc.approve(address(vault), depositAmount);

        // Deposit
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount);

        // Verify shares were minted
        assertGt(shares, 0, "Shares should be minted");
        assertEq(vault.getUserBalance(user), shares, "User should have shares");
        assertEq(vault.getTotalAssets(), depositAmount, "Total assets should increase");
    }

    /**
     * @notice Test deposit with zero amount
     */
    function test_DepositZeroAmount() public {
        vm.prank(user);
        vm.expectRevert("Deposit amount must be greater than 0");
        vault.deposit(0);
    }

    /**
     * @notice Test deposit without approval
     */
    function test_DepositWithoutApproval() public {
        uint256 depositAmount = 1000e6;

        vm.prank(user);
        vm.expectRevert();
        vault.deposit(depositAmount);
    }

    /**
     * @notice Test deposit with insufficient balance
     */
    function test_DepositInsufficientBalance() public {
        uint256 depositAmount = INITIAL_BALANCE + 1e6;

        vm.prank(user);
        usdc.approve(address(vault), depositAmount);

        vm.prank(user);
        vm.expectRevert();
        vault.deposit(depositAmount);
    }

    /**
     * @notice Test multiple deposits
     */
    function test_MultipleDeposits() public {
        uint256 deposit1 = 1000e6;
        uint256 deposit2 = 2000e6;

        // First deposit
        vm.prank(user);
        usdc.approve(address(vault), deposit1);
        vm.prank(user);
        uint256 shares1 = vault.deposit(deposit1);

        // Second deposit
        vm.prank(user);
        usdc.approve(address(vault), deposit2);
        vm.prank(user);
        uint256 shares2 = vault.deposit(deposit2);

        // Verify state
        assertEq(vault.getTotalAssets(), deposit1 + deposit2, "Total assets should be sum of deposits");
        assertEq(vault.getUserBalance(user), shares1 + shares2, "User shares should be sum");
    }

    /**
     * @notice Test deposit allocation across protocols
     */
    function test_DepositAllocation() public {
        uint256 depositAmount = 3000e6; // 3000 USDC

        vm.prank(user);
        usdc.approve(address(vault), depositAmount);

        vm.prank(user);
        vault.deposit(depositAmount);

        // Verify allocation across protocols (33% each)
        uint256 expectedPerProtocol = depositAmount / 3;
        
        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = adapters[i].balance();
            assertApproxEq(balance, expectedPerProtocol, 100, "Protocol should have ~33% of deposit");
        }
    }

    /**
     * @notice Test share price after deposit
     */
    function test_SharePriceAfterDeposit() public {
        uint256 depositAmount = 1000e6;

        vm.prank(user);
        usdc.approve(address(vault), depositAmount);

        vm.prank(user);
        vault.deposit(depositAmount);

        // Share price should be 1 USDC per share for first deposit
        uint256 sharePrice = vault.getSharePrice();
        assertEq(sharePrice, PRECISION, "Share price should be 1 USDC");
    }

    /**
     * @notice Test deposit event emission
     */
    function test_DepositEventEmission() public {
        uint256 depositAmount = 1000e6;

        vm.prank(user);
        usdc.approve(address(vault), depositAmount);

        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user, depositAmount, depositAmount); // First deposit: shares = amount
        vault.deposit(depositAmount);
    }

    /**
     * @notice Test user initial deposit tracking
     */
    function test_UserInitialDepositTracking() public {
        uint256 depositAmount = 1000e6;

        vm.prank(user);
        usdc.approve(address(vault), depositAmount);

        vm.prank(user);
        vault.deposit(depositAmount);

        // Verify initial deposit is tracked
        // (This would require a getter function in the vault)
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

    /**
     * @notice Assert two values are approximately equal with custom tolerance
     * @param a First value
     * @param b Second value
     * @param tolerance Tolerance (basis points)
     * @param message Error message
     */
    function assertApproxEq(uint256 a, uint256 b, uint256 tolerance, string memory message) internal pure {
        uint256 diff = a > b ? a - b : b - a;
        uint256 maxDiff = (b * tolerance) / 10000;
        require(diff <= maxDiff, message);
    }

    // ============ Events ============

    event Deposit(address indexed user, uint256 amount, uint256 shares);
}

// Import for interface
import {IProtocolAdapter} from "../../src/interfaces/IProtocolAdapter.sol";
