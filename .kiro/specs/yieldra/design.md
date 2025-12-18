# Design Document: Yieldra

## Overview

Yieldra is an AI-assisted yield optimization vault that operates on the principle: **"AI proposes. Oracles verify. Smart contracts decide."** The system consists of three integrated layers:

1. **Off-Chain AI Layer** (ElizaOS Agent) - Analyzes protocol metrics and proposes rebalancing strategies
2. **On-Chain Execution Layer** (Solidity Smart Contract) - Holds funds, enforces safety rules, and executes rebalancing
3. **Oracle Layer** (Pyth Network) - Provides real-time market data for volatility verification

Users deposit USDC into the vault, which automatically allocates funds across three yield protocols: Ondo Finance (USDY), Ethena (USDe), and Aave V3 (aUSDC). The AI agent continuously monitors protocol metrics and proposes rebalancing when yield optimization opportunities arise. Before any rebalancing executes, the smart contract verifies market conditions using Pyth oracle prices. If volatility is within safe bounds, the rebalancing proceeds; otherwise, it's rejected.

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
│  (Wallet, Deposit/Withdraw UI, Dashboard)                   │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼──────────┐    ┌────────▼──────────┐
│  AI Agent Layer  │    │  Smart Contract   │
│  (ElizaOS)       │    │  (Solidity)       │
│                  │    │                   │
│ • Read metrics   │    │ • Hold funds      │
│ • Propose        │    │ • Verify oracle   │
│   rebalance      │    │ • Execute trades  │
│ • Track memory   │    │ • Manage state    │
└────────┬─────────┘    └────────┬──────────┘
         │                       │
         └───────────┬───────────┘
                     │
        ┌────────────▼────────────┐
        │   Pyth Oracle Network   │
        │  (ETH/USD, BTC/USD,     │
        │   MNT/USD price feeds)  │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │  Yield Protocols        │
        │ • Ondo Finance (USDY)   │
        │ • Ethena (USDe)         │
        │ • Aave V3 (aUSDC)       │
        └────────────────────────┘
```

### Data Flow

**Deposit Flow:**
1. User approves USDC to vault
2. User calls `deposit(amount)`
3. Vault transfers USDC from user
4. Vault mints shares proportional to deposit
5. Vault allocates USDC across three protocols (33% each initially)
6. Vault emits Deposit event

**Rebalancing Flow:**
1. AI agent reads protocol APYs and risk signals
2. AI agent calculates optimal allocation
3. AI agent calls `rebalance(newAllocation)` on vault
4. Vault reads Pyth prices for ETH, BTC, MNT
5. Vault calculates 24-hour volatility for each asset
6. If volatility < 5% for all assets:
   - Vault exits over-allocated protocols
   - Vault enters under-allocated protocols
   - Vault emits Rebalance event
7. If volatility >= 5%:
   - Vault reverts transaction
   - Rebalance is rejected

**Withdrawal Flow:**
1. User calls `withdraw(shares)`
2. Vault calculates USDC value (shares × share price)
3. Vault exits necessary protocol positions
4. Vault transfers USDC to user
5. Vault burns shares
6. Vault emits Withdrawal event

## Components and Interfaces

### Smart Contract Components

#### 1. YieldraVault (Main Contract)

```solidity
interface IYieldraVault {
    // Deposit/Withdraw
    function deposit(uint256 amount) external returns (uint256 shares);
    function withdraw(uint256 shares) external returns (uint256 amount);
    
    // Rebalancing
    function rebalance(uint256[] calldata allocation) external;
    
    // State queries
    function totalAssets() external view returns (uint256);
    function sharePrice() external view returns (uint256);
    function userBalance(address user) external view returns (uint256);
    function currentAllocation() external view returns (uint256[] memory);
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdrawal(address indexed user, uint256 shares, uint256 amount);
    event Rebalance(uint256[] previousAllocation, uint256[] newAllocation);
    event Error(string reason);
}
```

**Responsibilities:**
- Accept USDC deposits and mint vault shares
- Manage user balances and share accounting
- Coordinate rebalancing across protocols
- Read oracle prices and verify safety conditions
- Execute protocol interactions
- Track allocation state

#### 2. ProtocolAdapter (Abstract Base)

```solidity
interface IProtocolAdapter {
    function deposit(uint256 amount) external returns (uint256 received);
    function withdraw(uint256 amount) external returns (uint256 received);
    function balance() external view returns (uint256);
    function getAPY() external view returns (uint256);
}
```

**Implementations:**
- `OndoAdapter` - Interacts with Ondo Finance (USDY)
- `EthenaAdapter` - Interacts with Ethena (USDe)
- `AaveAdapter` - Interacts with Aave V3 (aUSDC)

**Responsibilities:**
- Deposit USDC and receive yield assets
- Withdraw yield assets and receive USDC
- Query current balance and APY
- Handle protocol-specific logic

#### 3. OracleVerifier

```solidity
interface IOracleVerifier {
    function getPrice(bytes32 priceFeed) external view returns (uint256);
    function getVolatility(bytes32[] calldata priceFeeds) external view returns (uint256[] memory);
    function isVolatilityAcceptable(uint256[] calldata volatilities) external view returns (bool);
}
```

**Responsibilities:**
- Read Pyth oracle prices
- Calculate 24-hour volatility
- Verify price feed freshness (< 60 seconds old)
- Enforce volatility gate (< 5%)

#### 4. StateManager

```solidity
interface IStateManager {
    function updateAllocation(uint256[] calldata newAllocation) external;
    function recordRebalance(uint256[] calldata allocation) external;
    function getHistoricalAllocations() external view returns (uint256[][] memory);
}
```

**Responsibilities:**
- Persist allocation state
- Record rebalancing history
- Provide audit trail
- Maintain consistency across operations

### AI Agent Components

#### 1. MetricsAnalyzer

**Responsibilities:**
- Fetch protocol APYs from on-chain sources
- Calculate risk scores based on utilization and liquidity
- Identify rebalancing opportunities
- Evaluate yield vs. risk tradeoffs

#### 2. AllocationOptimizer

**Responsibilities:**
- Calculate optimal allocation given current metrics
- Enforce allocation constraints (10%-60% per protocol)
- Generate rebalance proposals
- Estimate expected yield improvement

#### 3. DecisionMemory

**Responsibilities:**
- Store past rebalancing decisions
- Track outcomes (actual vs. expected yield)
- Provide decision history for analysis
- Archive old decisions (keep last 100)

#### 4. ProposalExecutor

**Responsibilities:**
- Call vault `rebalance()` function
- Handle transaction failures gracefully
- Monitor rebalancing execution
- Update memory with outcome

## Data Models

### Vault State

```solidity
struct VaultState {
    uint256 totalAssets;           // Total USDC value in vault
    uint256 totalShares;           // Total shares outstanding
    uint256[] currentAllocation;   // [ondo%, ethena%, aave%]
    uint256 lastRebalanceTime;     // Timestamp of last rebalance
    mapping(address => uint256) userShares;  // User share balances
}
```

### Rebalance Proposal

```solidity
struct RebalanceProposal {
    uint256[] targetAllocation;    // [ondo%, ethena%, aave%]
    uint256 timestamp;             // When proposal was made
    string reasoning;              // AI reasoning (off-chain)
    bool executed;                 // Whether it was executed
}
```

### Protocol Metrics

```solidity
struct ProtocolMetrics {
    address protocol;              // Protocol address
    uint256 apy;                   // Current APY (basis points)
    uint256 utilization;           // Utilization rate (0-100%)
    uint256 liquidity;             // Available liquidity in USDC
    uint256 riskScore;             // Risk score (0-100)
    uint256 lastUpdated;           // Timestamp of last update
}
```

### Oracle Price Data

```solidity
struct PriceData {
    bytes32 priceFeed;             // Pyth price feed ID
    uint256 price;                 // Current price
    uint256 timestamp;             // Price timestamp
    uint256 confidence;            // Price confidence interval
}
```

## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Deposit Share Minting Consistency

*For any* valid USDC deposit amount and current vault state, the number of shares minted should be proportional to the deposit amount relative to the current share price, such that `shares_minted = deposit_amount / share_price`.

**Validates: Requirements 1.2**

### Property 2: Allocation Constraint Enforcement

*For any* rebalance proposal, if any protocol allocation is less than 10% or greater than 60%, the vault should reject the proposal and revert the transaction without modifying state.

**Validates: Requirements 2.4**

### Property 3: Volatility Gate Protection

*For any* rebalance proposal, if the 24-hour volatility of any asset (ETH, BTC, MNT) exceeds 5%, the vault should reject the proposal and revert the transaction.

**Validates: Requirements 3.3, 3.5**

### Property 4: Fund Conservation During Rebalancing

*For any* successful rebalancing operation, the total USDC value of the vault (sum of all protocol positions converted to USDC) should remain equal to the value before rebalancing, within a 0.5% tolerance for slippage and fees.

**Validates: Requirements 4.4**

### Property 5: Withdrawal Amount Accuracy

*For any* user withdrawal, the USDC amount received should equal the user's share count multiplied by the current share price, including their proportional share of accrued yield.

**Validates: Requirements 5.2, 5.4**

### Property 6: Share Price Monotonicity

*For any* sequence of deposits and rebalancing operations, the share price should never decrease unless a loss occurs in a protocol position.

**Validates: Requirements 6.2**

### Property 7: Allocation Tolerance After Rebalancing

*For any* completed rebalancing operation, the actual allocation of funds across protocols should match the target allocation within a 1% tolerance.

**Validates: Requirements 4.4**

### Property 8: Oracle Price Freshness

*For any* rebalance operation, the Pyth oracle prices used for volatility calculation should be no older than 60 seconds.

**Validates: Requirements 3.5**

### Property 9: User Share Balance Consistency

*For any* sequence of deposits and withdrawals by a user, the sum of all user share balances should equal the total shares outstanding in the vault.

**Validates: Requirements 8.1, 8.2**

### Property 10: Rebalance Proposal Idempotence

*For any* rebalance proposal that is rejected due to volatility or constraint violations, submitting the same proposal again should produce the same result (rejection or acceptance based on current conditions).

**Validates: Requirements 2.5, 3.3**

## Error Handling

### Deposit Errors

- **Zero Amount**: Reject deposits of 0 USDC
- **Insufficient Balance**: Reject if user balance < deposit amount
- **Approval Missing**: Reject if user hasn't approved USDC to vault
- **Protocol Failure**: If protocol deposit fails, revert entire transaction

### Rebalancing Errors

- **Invalid Allocation**: Reject if any protocol < 10% or > 60%
- **High Volatility**: Reject if any asset volatility >= 5%
- **Stale Oracle**: Reject if price feed > 60 seconds old
- **Protocol Interaction Failure**: Revert transaction if protocol swap fails
- **Slippage Exceeded**: Revert if actual slippage > 1%

### Withdrawal Errors

- **Insufficient Shares**: Reject if user shares < requested amount
- **Protocol Liquidity**: Revert if protocol cannot provide sufficient USDC
- **State Inconsistency**: Halt withdrawal if vault detects balance mismatch

### AI Agent Errors

- **Malformed Proposal**: Reject if allocation array length != 3
- **Network Failure**: Retry proposal submission up to 3 times
- **Memory Overflow**: Archive old decisions when memory reaches 100 entries

## Testing Strategy

### Unit Testing

Unit tests verify specific examples and edge cases:

- **Deposit Tests**: Valid deposits, zero amounts, insufficient balance, approval failures
- **Withdrawal Tests**: Valid withdrawals, insufficient shares, protocol failures
- **Rebalancing Tests**: Valid allocations, constraint violations, volatility rejection
- **Oracle Tests**: Price reading, volatility calculation, freshness checks
- **State Tests**: Share price calculation, allocation tracking, consistency

### Property-Based Testing

Property-based tests verify universal properties across all inputs using a PBT library. For this project, we'll use **Foundry's property testing framework** (built into Foundry for Solidity).

**Configuration:**
- Minimum 100 iterations per property test
- Generators constrain to valid input ranges (e.g., allocations 0-100%, amounts > 0)
- Each property test tagged with requirement reference

**Property Test Format:**
```solidity
// **Feature: yieldra, Property 1: Deposit Share Minting Consistency**
// **Validates: Requirements 1.2**
function testProperty_DepositShareMinting(uint256 depositAmount) public {
    // Test implementation
}
```

**Properties to Test:**
1. Deposit Share Minting Consistency (Property 1)
2. Allocation Constraint Enforcement (Property 2)
3. Volatility Gate Protection (Property 3)
4. Fund Conservation During Rebalancing (Property 4)
5. Withdrawal Amount Accuracy (Property 5)
6. Share Price Monotonicity (Property 6)
7. Allocation Tolerance After Rebalancing (Property 7)
8. Oracle Price Freshness (Property 8)
9. User Share Balance Consistency (Property 9)
10. Rebalance Proposal Idempotence (Property 10)

### Integration Testing

Integration tests verify interactions between components:

- **Deposit → Allocation**: Verify funds are allocated to protocols after deposit
- **Rebalance → Execution**: Verify rebalancing executes correctly across protocols
- **Withdrawal → Fund Recovery**: Verify users receive correct USDC after withdrawal
- **Oracle → Safety Gate**: Verify oracle data blocks unsafe rebalancing
- **AI → Vault**: Verify AI proposals are processed correctly by vault

