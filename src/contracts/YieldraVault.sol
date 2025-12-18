// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IYieldraVault} from "../interfaces/IYieldraVault.sol";
import {IProtocolAdapter} from "../interfaces/IProtocolAdapter.sol";
import {IOracleVerifier} from "../interfaces/IOracleVerifier.sol";

/**
 * @title YieldraVault
 * @notice Main vault contract for Yieldra yield optimization
 * @dev Manages deposits, withdrawals, and rebalancing across multiple protocols
 */
contract YieldraVault is IYieldraVault, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ============ Constants ============

    uint256 constant PRECISION = 1e18;
    uint256 constant PERCENTAGE_PRECISION = 100; // 100 = 1%
    uint256 constant MIN_ALLOCATION = 10 * PERCENTAGE_PRECISION; // 10%
    uint256 constant MAX_ALLOCATION = 60 * PERCENTAGE_PRECISION; // 60%
    uint256 constant TOTAL_ALLOCATION = 100 * PERCENTAGE_PRECISION; // 100%
    uint256 constant ALLOCATION_TOLERANCE = 1 * PERCENTAGE_PRECISION; // 1%

    // ============ State Variables ============

    IERC20 public immutable usdc;
    IOracleVerifier public oracleVerifier;

    // Vault state
    uint256 public totalAssets; // Total USDC value in vault
    uint256 public totalShares; // Total shares outstanding
    uint256[] public currentAllocation; // [ondo%, ethena%, aave%]
    uint256 public lastRebalanceTime;

    // User balances
    mapping(address => uint256) public userShares;

    // Protocol adapters
    IProtocolAdapter[] public adapters; // [ondo, ethena, aave]

    // Historical data
    uint256[][] public allocationHistory;
    uint256[] public allocationTimestamps;

    // User deposit tracking for yield calculation
    mapping(address => uint256) public userInitialDeposit;

    // Oracle price feeds
    bytes32 public ethUsdFeed;
    bytes32 public btcUsdFeed;
    bytes32 public mntUsdFeed;

    // ============ Events ============

    event AllocationUpdated(uint256[] newAllocation, uint256 timestamp);

    // ============ Constructor ============

    constructor(address _usdc) {
        require(_usdc != address(0), "Invalid USDC address");
        usdc = IERC20(_usdc);
        
        // Initialize allocation to 33% each
        currentAllocation = new uint256[](3);
        currentAllocation[0] = 33 * PERCENTAGE_PRECISION + 33; // 33.33%
        currentAllocation[1] = 33 * PERCENTAGE_PRECISION + 33; // 33.33%
        currentAllocation[2] = 33 * PERCENTAGE_PRECISION + 34; // 33.34%
    }

    // ============ Setup ============

    /**
     * @notice Set protocol adapters
     * @param _adapters Array of protocol adapters [ondo, ethena, aave]
     */
    function setAdapters(IProtocolAdapter[] calldata _adapters) external onlyOwner {
        require(_adapters.length == 3, "Must provide exactly 3 adapters");
        require(adapters.length == 0, "Adapters already set");
        
        for (uint256 i = 0; i < 3; i++) {
            require(address(_adapters[i]) != address(0), "Invalid adapter");
            adapters.push(_adapters[i]);
        }
    }

    /**
     * @notice Set oracle verifier
     * @param _oracleVerifier Oracle verifier contract address
     */
    function setOracleVerifier(address _oracleVerifier) external onlyOwner {
        require(_oracleVerifier != address(0), "Invalid oracle verifier");
        oracleVerifier = IOracleVerifier(_oracleVerifier);
    }

    /**
     * @notice Set oracle price feeds
     * @param _ethUsdFeed ETH/USD price feed ID
     * @param _btcUsdFeed BTC/USD price feed ID
     * @param _mntUsdFeed MNT/USD price feed ID
     */
    function setOraclePriceFeeds(bytes32 _ethUsdFeed, bytes32 _btcUsdFeed, bytes32 _mntUsdFeed) external onlyOwner {
        ethUsdFeed = _ethUsdFeed;
        btcUsdFeed = _btcUsdFeed;
        mntUsdFeed = _mntUsdFeed;
    }

    // ============ Deposit ============

    /**
     * @notice Deposit USDC into the vault
     * @param amount Amount of USDC to deposit
     * @return shares Number of vault shares minted
     */
    function deposit(uint256 amount) external nonReentrant returns (uint256 shares) {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(adapters.length == 3, "Adapters not initialized");

        // Calculate shares to mint
        shares = _calculateSharesForDeposit(amount);
        require(shares > 0, "Deposit amount too small");

        // Transfer USDC from user to vault
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        // Update state
        totalAssets += amount;
        totalShares += shares;
        userShares[msg.sender] += shares;
        userInitialDeposit[msg.sender] += amount;

        // Allocate funds across protocols
        _allocateDeposit(amount);

        // Emit event
        emit Deposit(msg.sender, amount, shares);

        return shares;
    }

    // ============ Withdrawal ============

    /**
     * @notice Withdraw USDC from the vault
     * @param shares Number of vault shares to burn
     * @return amount Amount of USDC returned to user
     */
    function withdraw(uint256 shares) external nonReentrant returns (uint256 amount) {
        require(shares > 0, "Withdrawal shares must be greater than 0");
        require(userShares[msg.sender] >= shares, "Insufficient shares");

        // Calculate USDC value
        amount = _calculateUSDCForShares(shares);
        require(amount > 0, "Withdrawal amount too small");

        // Exit protocol positions to obtain USDC
        _exitProtocolPositions(amount);

        // Transfer USDC to user
        usdc.safeTransfer(msg.sender, amount);

        // Update state
        totalAssets -= amount;
        totalShares -= shares;
        userShares[msg.sender] -= shares;

        // Emit event
        emit Withdrawal(msg.sender, shares, amount);

        return amount;
    }

    // ============ Rebalancing ============

    /**
     * @notice Propose and execute a rebalancing of vault funds
     * @param allocation Target allocation percentages [ondo%, ethena%, aave%]
     */
    function rebalance(uint256[] calldata allocation) external onlyOwner {
        require(allocation.length == 3, "Invalid allocation array length");
        require(adapters.length == 3, "Adapters not initialized");
        require(address(oracleVerifier) != address(0), "Oracle verifier not set");

        // Validate allocation constraints
        _validateAllocation(allocation);

        // Verify oracle conditions
        _verifyOracleConditions();

        // Store previous allocation
        uint256[] memory previousAllocation = currentAllocation;

        // Execute rebalancing
        _executeRebalancing(allocation);

        // Update state
        currentAllocation = allocation;
        lastRebalanceTime = block.timestamp;

        // Record in history
        allocationHistory.push(allocation);
        allocationTimestamps.push(block.timestamp);

        // Emit event
        emit Rebalance(previousAllocation, allocation, block.timestamp);
        emit AllocationUpdated(allocation, block.timestamp);
    }

    // ============ State Queries ============

    /**
     * @notice Get total assets under management in USDC
     * @return Total USDC value of all vault positions
     */
    function getTotalAssets() external view returns (uint256) {
        return totalAssets;
    }

    /**
     * @notice Get current share price in USDC
     * @return Share price (USDC per share, scaled by 1e18)
     */
    function getSharePrice() external view returns (uint256) {
        if (totalShares == 0) return PRECISION;
        return (totalAssets * PRECISION) / totalShares;
    }

    /**
     * @notice Get user's vault share balance
     * @param user User address
     * @return User's share balance
     */
    function getUserBalance(address user) external view returns (uint256) {
        return userShares[user];
    }

    /**
     * @notice Get current allocation across protocols
     * @return Array of allocation percentages [ondo%, ethena%, aave%]
     */
    function getCurrentAllocation() external view returns (uint256[] memory) {
        return currentAllocation;
    }

    /**
     * @notice Get user's USDC value (shares × share price)
     * @param user User address
     * @return USDC value of user's shares
     */
    function getUserValue(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        return (userShares[user] * totalAssets) / totalShares;
    }

    /**
     * @notice Get user's yield earned
     * @param user User address
     * @return Yield earned in USDC
     */
    function getYieldEarned(address user) external view returns (uint256) {
        uint256 currentValue = this.getUserValue(user);
        uint256 initialDeposit = userInitialDeposit[user];
        
        if (currentValue > initialDeposit) {
            return currentValue - initialDeposit;
        }
        return 0;
    }

    /**
     * @notice Get allocation history
     * @return Array of historical allocations
     */
    function getAllocationHistory() external view returns (uint256[][] memory) {
        return allocationHistory;
    }

    /**
     * @notice Get allocation timestamps
     * @return Array of timestamps for each allocation change
     */
    function getAllocationTimestamps() external view returns (uint256[] memory) {
        return allocationTimestamps;
    }

    // ============ Internal Functions ============

    /**
     * @notice Calculate shares to mint for a deposit
     * @param amount USDC amount to deposit
     * @return shares Shares to mint
     */
    function _calculateSharesForDeposit(uint256 amount) internal view returns (uint256 shares) {
        if (totalShares == 0) {
            // First deposit: 1 share = 1 USDC
            return amount;
        }
        // shares = amount * totalShares / totalAssets
        return (amount * totalShares) / totalAssets;
    }

    /**
     * @notice Calculate USDC value for shares
     * @param shares Number of shares
     * @return amount USDC value
     */
    function _calculateUSDCForShares(uint256 shares) internal view returns (uint256 amount) {
        if (totalShares == 0) return 0;
        return (shares * totalAssets) / totalShares;
    }

    /**
     * @notice Allocate deposited USDC across protocols
     * @param amount USDC amount to allocate
     */
    function _allocateDeposit(uint256 amount) internal {
        for (uint256 i = 0; i < 3; i++) {
            uint256 allocationAmount = (amount * currentAllocation[i]) / TOTAL_ALLOCATION;
            if (allocationAmount > 0) {
                usdc.safeApprove(address(adapters[i]), allocationAmount);
                adapters[i].deposit(allocationAmount);
            }
        }
    }

    /**
     * @notice Exit protocol positions to obtain USDC
     * @param amount USDC amount needed
     */
    function _exitProtocolPositions(uint256 amount) internal {
        uint256 remaining = amount;
        
        for (uint256 i = 0; i < 3 && remaining > 0; i++) {
            uint256 balance = adapters[i].balance();
            if (balance > 0) {
                uint256 toWithdraw = balance < remaining ? balance : remaining;
                adapters[i].withdraw(toWithdraw);
                remaining -= toWithdraw;
            }
        }

        require(remaining == 0, "Insufficient liquidity in protocols");
    }

    /**
     * @notice Validate allocation constraints
     * @param allocation Target allocation percentages
     */
    function _validateAllocation(uint256[] calldata allocation) internal pure {
        uint256 total = 0;
        
        for (uint256 i = 0; i < 3; i++) {
            require(allocation[i] >= MIN_ALLOCATION, "Allocation below minimum");
            require(allocation[i] <= MAX_ALLOCATION, "Allocation above maximum");
            total += allocation[i];
        }
        
        require(total == TOTAL_ALLOCATION, "Allocation must sum to 100%");
    }

    /**
     * @notice Verify oracle conditions for rebalancing
     */
    function _verifyOracleConditions() internal view {
        // Check price freshness
        require(oracleVerifier.isPriceFresh(ethUsdFeed), "ETH price is stale");
        require(oracleVerifier.isPriceFresh(btcUsdFeed), "BTC price is stale");
        require(oracleVerifier.isPriceFresh(mntUsdFeed), "MNT price is stale");

        // Check volatility
        uint256[] memory volatilities = new uint256[](3);
        volatilities[0] = oracleVerifier.getVolatility(ethUsdFeed);
        volatilities[1] = oracleVerifier.getVolatility(btcUsdFeed);
        volatilities[2] = oracleVerifier.getVolatility(mntUsdFeed);

        require(oracleVerifier.isVolatilityAcceptable(volatilities), "Market volatility too high");
    }

    /**
     * @notice Execute rebalancing across protocols
     * @param targetAllocation Target allocation percentages
     */
    function _executeRebalancing(uint256[] calldata targetAllocation) internal {
        // Get current balances in USDC value
        uint256[] memory currentBalances = new uint256[](3);
        uint256 totalValue = 0;

        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = adapters[i].balance();
            // For simplicity, assume 1:1 conversion to USDC
            currentBalances[i] = balance;
            totalValue += balance;
        }

        // Exit over-allocated positions
        for (uint256 i = 0; i < 3; i++) {
            uint256 targetValue = (totalAssets * targetAllocation[i]) / TOTAL_ALLOCATION;
            if (currentBalances[i] > targetValue) {
                uint256 toExit = currentBalances[i] - targetValue;
                adapters[i].withdraw(toExit);
            }
        }

        // Enter under-allocated positions
        for (uint256 i = 0; i < 3; i++) {
            uint256 targetValue = (totalAssets * targetAllocation[i]) / TOTAL_ALLOCATION;
            uint256 currentValue = adapters[i].balance();
            if (currentValue < targetValue) {
                uint256 toEnter = targetValue - currentValue;
                usdc.safeApprove(address(adapters[i]), toEnter);
                adapters[i].deposit(toEnter);
            }
        }
    }
}
