# Requirements Document: Yieldra

## Introduction

Yieldra is an AI-assisted yield optimization vault on the Mantle Network that enables users to deposit USDC and automatically rebalance across multiple yield-generating protocols (Ondo Finance, Ethena, and Aave V3). The system uses an AI agent to propose rebalancing strategies based on protocol metrics and risk signals, while oracle price feeds from Pyth Network enforce market-aware safety checks. All execution decisions are made entirely on-chain through smart contracts, ensuring that AI proposals cannot bypass safety rules or move funds without oracle verification.

## Glossary

- **Vault**: The smart contract that holds user deposits and manages fund allocation across yield protocols
- **USDC**: USD Coin, the base deposit asset on Mantle Network
- **Yield Assets**: USDY (Ondo), USDe (Ethena), aUSDC (Aave V3) - interest-bearing tokens held by the vault
- **Rebalancing**: The process of reallocating funds between yield protocols to optimize returns
- **AI Agent**: ElizaOS-based agent that analyzes protocol metrics and proposes rebalancing actions
- **Oracle**: Pyth Network price feed providing real-time market data (ETH/USD, BTC/USD, MNT/USD)
- **Volatility Gate**: On-chain safety rule that prevents rebalancing during high market volatility
- **APY**: Annual Percentage Yield - the expected return from a yield protocol
- **Risk Signal**: Metric indicating protocol health, liquidity, or other risk factors
- **Mantle Network**: EVM-compatible blockchain where the vault is deployed

## Requirements

### Requirement 1: User Deposit and Vault Entry

**User Story:** As a user, I want to deposit USDC into the Yieldra vault, so that my funds can be allocated across yield-generating protocols.

#### Acceptance Criteria

1. WHEN a user approves USDC to the vault contract THEN the vault SHALL accept the approval and record it for future deposits
2. WHEN a user calls the deposit function with a valid USDC amount THEN the vault SHALL transfer USDC from the user's wallet and mint vault shares proportional to the deposit
3. WHEN a user deposits USDC THEN the vault SHALL immediately allocate the funds across the three supported protocols (Ondo, Ethena, Aave) according to the current allocation strategy
4. IF a user attempts to deposit zero USDC or an amount exceeding their wallet balance THEN the vault SHALL reject the deposit and revert the transaction
5. WHEN a user deposits USDC THEN the vault SHALL emit a Deposit event containing the user address, deposit amount, and vault shares minted

### Requirement 2: AI Agent Rebalancing Proposal

**User Story:** As an AI agent, I want to analyze protocol metrics and propose rebalancing actions, so that the vault can optimize yield while respecting safety constraints.

#### Acceptance Criteria

1. WHEN the AI agent reads protocol metrics (APY, utilization, risk signals) THEN the AI agent SHALL evaluate the current allocation and determine if rebalancing would improve yield
2. WHEN the AI agent identifies a rebalancing opportunity THEN the AI agent SHALL construct a rebalance proposal specifying the target allocation percentages for each protocol
3. WHEN the AI agent calls the rebalance function on the vault THEN the vault SHALL accept the proposal and proceed to oracle verification without moving funds
4. IF the AI agent proposes an allocation where any protocol receives less than 10% or more than 60% of total funds THEN the vault SHALL reject the proposal as violating allocation constraints
5. WHEN the AI agent proposes a rebalance THEN the vault SHALL record the proposal timestamp and proposed allocation for audit purposes

### Requirement 3: Oracle Verification and Safety Gates

**User Story:** As a vault operator, I want oracle price feeds to verify market conditions before executing rebalancing, so that the system cannot execute during unsafe market conditions.

#### Acceptance Criteria

1. WHEN a rebalance proposal is submitted THEN the vault SHALL read the latest ETH/USD, BTC/USD, and MNT/USD prices from Pyth Network
2. WHEN the vault reads oracle prices THEN the vault SHALL calculate the 24-hour price volatility for each asset
3. IF any asset's 24-hour volatility exceeds 5% THEN the vault SHALL reject the rebalance proposal and revert the transaction
4. WHEN all volatility checks pass THEN the vault SHALL proceed to execute the rebalancing allocation
5. IF the Pyth oracle price feed is stale (older than 60 seconds) THEN the vault SHALL reject the rebalance proposal and revert the transaction

### Requirement 4: Fund Rebalancing and Protocol Interaction

**User Story:** As the vault, I want to execute approved rebalancing by moving funds between protocols, so that the vault maintains the target allocation.

#### Acceptance Criteria

1. WHEN a rebalance proposal passes oracle verification THEN the vault SHALL exit positions from protocols with above-target allocation
2. WHEN the vault exits a protocol position THEN the vault SHALL receive the corresponding yield asset (USDY, USDe, or aUSDC) and convert it back to USDC
3. WHEN the vault has USDC available THEN the vault SHALL enter new positions in protocols with below-target allocation by swapping USDC for the corresponding yield asset
4. WHEN rebalancing is complete THEN the vault SHALL verify that the actual allocation matches the target allocation within a 1% tolerance
5. WHEN rebalancing completes successfully THEN the vault SHALL emit a Rebalance event containing the previous allocation, new allocation, and timestamp

### Requirement 5: User Withdrawal and Vault Exit

**User Story:** As a user, I want to withdraw my USDC from the vault, so that I can access my funds and accrued yield.

#### Acceptance Criteria

1. WHEN a user calls the withdraw function with a valid vault share amount THEN the vault SHALL burn the shares and calculate the corresponding USDC value
2. WHEN the vault calculates withdrawal amount THEN the vault SHALL include the user's proportional share of accrued yield from all protocols
3. WHEN a user withdraws THEN the vault SHALL exit the necessary protocol positions to obtain sufficient USDC for the withdrawal
4. WHEN the vault has obtained sufficient USDC THEN the vault SHALL transfer the USDC to the user's wallet
5. WHEN a user withdraws THEN the vault SHALL emit a Withdrawal event containing the user address, vault shares burned, and USDC amount transferred

### Requirement 6: Yield Tracking and Reporting

**User Story:** As a user, I want to track the yield earned on my deposit, so that I can verify the vault's performance.

#### Acceptance Criteria

1. WHEN a user queries their vault share balance THEN the system SHALL calculate the current USDC value by multiplying shares by the current share price
2. WHEN the vault accrues yield from protocols THEN the vault SHALL update the share price to reflect the increased total value
3. WHEN a user queries their yield earned THEN the system SHALL calculate the difference between current USDC value and original deposit amount
4. WHEN the vault completes a rebalancing action THEN the vault SHALL record the allocation change and timestamp for historical tracking
5. WHEN a user requests yield history THEN the system SHALL return a time-series of share prices and allocation changes

### Requirement 7: Protocol Integration and Asset Management

**User Story:** As the vault, I want to interact with Ondo Finance, Ethena, and Aave V3 protocols, so that funds can be allocated across multiple yield sources.

#### Acceptance Criteria

1. WHEN the vault needs to enter a protocol position THEN the vault SHALL approve the protocol to spend USDC (one-time) and then deposit USDC to receive the corresponding yield asset
2. WHEN the vault holds USDY, USDe, or aUSDC THEN the vault SHALL track the balance of each yield asset separately
3. WHEN the vault needs to exit a protocol position THEN the vault SHALL withdraw the yield asset and receive USDC back
4. WHEN the vault interacts with a protocol THEN the vault SHALL handle protocol-specific return values and error conditions gracefully
5. WHEN the vault receives yield asset balances from protocols THEN the vault SHALL convert them to USD values using current market prices for allocation calculations

### Requirement 8: Data Persistence and State Management

**User Story:** As the vault, I want to maintain accurate state across deposits, rebalancing, and withdrawals, so that all operations are consistent and auditable.

#### Acceptance Criteria

1. WHEN the vault executes any state-changing operation THEN the vault SHALL update the total assets under management (AUM) and share price atomically
2. WHEN a user deposits or withdraws THEN the vault SHALL update the user's share balance and the total shares outstanding
3. WHEN the vault completes a rebalancing action THEN the vault SHALL persist the new allocation percentages and timestamp
4. WHEN the vault state is queried THEN the system SHALL return consistent values for total AUM, share price, and user balances
5. WHEN the vault is deployed THEN the vault SHALL initialize with zero AUM, zero shares, and zero allocation across protocols

### Requirement 9: Error Handling and Transaction Safety

**User Story:** As a user, I want the vault to handle errors gracefully, so that failed operations do not corrupt state or lose funds.

#### Acceptance Criteria

1. IF a protocol interaction fails THEN the vault SHALL revert the entire transaction and restore the previous state
2. IF a user attempts an invalid operation (e.g., withdraw more than their balance) THEN the vault SHALL reject the operation with a clear error message
3. WHEN the vault detects an inconsistency between expected and actual balances THEN the vault SHALL halt rebalancing and emit an alert event
4. IF the AI agent submits a malformed rebalance proposal THEN the vault SHALL reject it without processing
5. WHEN any critical operation fails THEN the vault SHALL emit an Error event with details for off-chain monitoring

### Requirement 10: AI Agent Decision Logic and Memory

**User Story:** As an AI agent, I want to track past rebalancing decisions and learn from them, so that future proposals improve over time.

#### Acceptance Criteria

1. WHEN the AI agent makes a rebalancing decision THEN the AI agent SHALL store the decision (timestamp, proposed allocation, outcome) in memory
2. WHEN the AI agent evaluates a new rebalancing opportunity THEN the AI agent SHALL consider past decisions and their outcomes to avoid repeating unsuccessful strategies
3. WHEN the AI agent reads protocol metrics THEN the AI agent SHALL weight recent data more heavily than historical data in its analysis
4. WHEN the AI agent proposes a rebalance THEN the AI agent SHALL include reasoning (which protocols improved, which declined) in the proposal metadata
5. WHEN the AI agent's memory reaches capacity THEN the AI agent SHALL archive old decisions and retain only the most recent 100 decisions

