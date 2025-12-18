# Implementation Plan: Yieldra

## Overview

This implementation plan breaks down the Yieldra yield optimization vault into discrete, manageable coding tasks. Each task builds incrementally on previous tasks, starting with core smart contract infrastructure, moving through protocol integrations, and finishing with AI agent implementation and comprehensive testing.

---

## Tasks

- [x] 1. Set up project structure and Solidity development environment
  - Initialize Foundry project with proper directory structure
  - Configure Solidity compiler (0.8.20+) and dependencies
  - Set up environment variables for Mantle testnet/mainnet
  - Create base contract interfaces and abstract classes
  - _Requirements: 1.1, 7.1_

- [x] 2. Implement core vault state management and data structures
  - Create VaultState struct and storage variables
  - Implement share accounting logic (totalShares, userShares mapping)
  - Implement share price calculation (totalAssets / totalShares)
  - Create state getter functions (totalAssets, sharePrice, userBalance)
  - _Requirements: 8.1, 8.2, 8.5_

- [ ]* 2.1 Write property test for share price calculation
  - **Property 6: Share Price Monotonicity**
  - **Validates: Requirements 6.2**

- [x] 3. Implement USDC deposit functionality
  - Create deposit function that accepts USDC amount
  - Implement share minting logic (shares = amount / sharePrice)
  - Add USDC transfer from user to vault
  - Implement initial allocation across three protocols (33% each)
  - Emit Deposit event with user, amount, and shares
  - _Requirements: 1.1, 1.2, 1.3, 1.5_

- [ ]* 3.1 Write property test for deposit share minting
  - **Property 1: Deposit Share Minting Consistency**
  - **Validates: Requirements 1.2**

- [ ]* 3.2 Write property test for deposit allocation
  - **Property 3: Fund Conservation During Rebalancing** (applies to initial allocation)
  - **Validates: Requirements 1.3**

- [ ]* 3.3 Write unit tests for deposit edge cases
  - Test zero amount rejection
  - Test insufficient balance rejection
  - Test approval failure handling
  - _Requirements: 1.4_

- [ ] 4. Implement protocol adapter interfaces and base classes
  - Create IProtocolAdapter interface with deposit, withdraw, balance, getAPY
  - Create abstract ProtocolAdapter base class
  - Implement error handling for protocol interactions
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 5. Implement Ondo Finance adapter (USDY)
  - Create OndoAdapter contract inheriting from ProtocolAdapter
  - Implement deposit function (USDC → USDY)
  - Implement withdraw function (USDY → USDC)
  - Implement balance tracking for USDY
  - Implement getAPY function (read from Ondo)
  - _Requirements: 7.1, 7.2, 7.3, 7.5_

- [ ] 6. Implement Ethena adapter (USDe)
  - Create EthenaAdapter contract inheriting from ProtocolAdapter
  - Implement deposit function (USDC → USDe)
  - Implement withdraw function (USDe → USDC)
  - Implement balance tracking for USDe
  - Implement getAPY function (read from Ethena)
  - _Requirements: 7.1, 7.2, 7.3, 7.5_

- [ ] 7. Implement Aave V3 adapter (aUSDC)
  - Create AaveAdapter contract inheriting from ProtocolAdapter
  - Implement deposit function (USDC → aUSDC)
  - Implement withdraw function (aUSDC → USDC)
  - Implement balance tracking for aUSDC
  - Implement getAPY function (read from Aave)
  - _Requirements: 7.1, 7.2, 7.3, 7.5_

- [ ]* 7.1 Write property test for protocol adapter consistency
  - **Property 4: Fund Conservation During Rebalancing**
  - **Validates: Requirements 7.1, 7.3**

- [ ] 8. Implement Oracle Verifier for Pyth price feeds
  - Create OracleVerifier contract
  - Implement getPrice function (read ETH/USD, BTC/USD, MNT/USD from Pyth)
  - Implement price freshness check (< 60 seconds)
  - Implement volatility calculation (24-hour price volatility)
  - Implement isVolatilityAcceptable function (< 5% threshold)
  - _Requirements: 3.1, 3.2, 3.5_

- [ ]* 8.1 Write property test for oracle price freshness
  - **Property 8: Oracle Price Freshness**
  - **Validates: Requirements 3.5**

- [ ]* 8.2 Write property test for volatility calculation
  - **Property 3: Volatility Gate Protection**
  - **Validates: Requirements 3.3**

- [ ] 9. Implement rebalancing proposal validation
  - Create rebalance function that accepts target allocation array
  - Validate allocation constraints (10%-60% per protocol)
  - Validate allocation array length (must be 3)
  - Record proposal timestamp and allocation for audit
  - Emit proposal event
  - _Requirements: 2.3, 2.4, 2.5_

- [ ]* 9.1 Write property test for allocation constraints
  - **Property 2: Allocation Constraint Enforcement**
  - **Validates: Requirements 2.4**

- [ ] 10. Implement oracle verification in rebalancing
  - Integrate OracleVerifier into rebalance function
  - Read Pyth prices before rebalancing
  - Calculate volatility for ETH, BTC, MNT
  - Check volatility against 5% threshold
  - Revert if volatility too high or prices stale
  - _Requirements: 3.1, 3.2, 3.3, 3.5_

- [ ]* 10.1 Write property test for volatility gate
  - **Property 3: Volatility Gate Protection**
  - **Validates: Requirements 3.3, 3.5**

- [ ] 11. Implement rebalancing execution logic
  - Calculate current allocation percentages
  - Identify over-allocated and under-allocated protocols
  - Exit positions from over-allocated protocols
  - Enter positions in under-allocated protocols
  - Verify final allocation within 1% tolerance
  - Emit Rebalance event with previous and new allocation
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ]* 11.1 Write property test for allocation tolerance
  - **Property 7: Allocation Tolerance After Rebalancing**
  - **Validates: Requirements 4.4**

- [ ]* 11.2 Write property test for fund conservation
  - **Property 4: Fund Conservation During Rebalancing**
  - **Validates: Requirements 4.4**

- [ ] 12. Implement withdrawal functionality
  - Create withdraw function that accepts share amount
  - Calculate USDC value (shares × sharePrice)
  - Include user's proportional share of accrued yield
  - Exit necessary protocol positions to obtain USDC
  - Transfer USDC to user
  - Burn shares from user balance
  - Emit Withdrawal event
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ]* 12.1 Write property test for withdrawal accuracy
  - **Property 5: Withdrawal Amount Accuracy**
  - **Validates: Requirements 5.2, 5.4**

- [ ]* 12.2 Write unit tests for withdrawal edge cases
  - Test insufficient shares rejection
  - Test protocol liquidity failures
  - Test state inconsistency detection
  - _Requirements: 5.1_

- [ ] 13. Implement yield tracking and reporting
  - Create functions to query current share price
  - Implement yield calculation (current_value - original_deposit)
  - Create historical allocation tracking
  - Implement getHistoricalAllocations function
  - Store allocation snapshots with timestamps
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 13.1 Write property test for share price calculation
  - **Property 6: Share Price Monotonicity**
  - **Validates: Requirements 6.2**

- [ ]* 13.2 Write property test for yield calculation
  - **Property 6: Share Price Monotonicity**
  - **Validates: Requirements 6.3**

- [ ] 14. Implement state consistency and atomicity
  - Ensure AUM and share price update atomically
  - Implement consistency checks for user balances
  - Verify total shares equals sum of user shares
  - Add state validation functions
  - Implement emergency halt mechanism for inconsistencies
  - _Requirements: 8.1, 8.2, 8.4_

- [ ]* 14.1 Write property test for state consistency
  - **Property 9: User Share Balance Consistency**
  - **Validates: Requirements 8.1, 8.2**

- [ ] 15. Implement comprehensive error handling
  - Add try-catch for all protocol interactions
  - Implement graceful failure modes
  - Add error event emission for monitoring
  - Implement transaction reversion on failures
  - Add validation for all user inputs
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ]* 15.1 Write unit tests for error handling
  - Test protocol interaction failures
  - Test invalid operations
  - Test balance inconsistencies
  - Test malformed proposals
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 16. Checkpoint - Ensure all smart contract tests pass
  - Run all unit and property tests for smart contracts
  - Verify 100% test pass rate
  - Check test coverage for core functions
  - Ask the user if questions arise

- [ ] 17. Implement AI Agent - MetricsAnalyzer component
  - Create MetricsAnalyzer class in ElizaOS
  - Implement protocol metrics fetching (APY, utilization, liquidity)
  - Implement risk score calculation
  - Implement rebalancing opportunity detection
  - Add yield vs. risk evaluation logic
  - _Requirements: 2.1, 10.3_

- [ ] 18. Implement AI Agent - AllocationOptimizer component
  - Create AllocationOptimizer class
  - Implement optimal allocation calculation
  - Enforce allocation constraints (10%-60% per protocol)
  - Generate rebalance proposals
  - Estimate expected yield improvement
  - _Requirements: 2.2, 2.4_

- [ ] 19. Implement AI Agent - DecisionMemory component
  - Create DecisionMemory class
  - Implement decision storage (timestamp, allocation, outcome)
  - Implement decision history retrieval
  - Implement memory archiving (keep last 100 decisions)
  - Add decision outcome tracking
  - _Requirements: 10.1, 10.2, 10.5_

- [ ] 20. Implement AI Agent - ProposalExecutor component
  - Create ProposalExecutor class
  - Implement vault rebalance function calling
  - Implement transaction failure handling (retry up to 3 times)
  - Implement execution monitoring
  - Update memory with execution outcome
  - _Requirements: 2.3, 10.1, 10.4_

- [ ]* 20.1 Write unit tests for AI agent components
  - Test MetricsAnalyzer with mock protocol data
  - Test AllocationOptimizer with various scenarios
  - Test DecisionMemory storage and retrieval
  - Test ProposalExecutor with mock vault
  - _Requirements: 2.1, 2.2, 10.1, 10.2_

- [ ] 21. Integrate AI Agent with Vault
  - Connect ProposalExecutor to vault rebalance function
  - Implement proposal submission flow
  - Add monitoring for proposal acceptance/rejection
  - Implement feedback loop to AI memory
  - _Requirements: 2.3, 10.1, 10.4_

- [ ] 22. Implement on-chain/off-chain data pipeline
  - Create data fetching service for protocol metrics
  - Implement oracle price caching
  - Create event listener for vault events
  - Implement state synchronization between on-chain and off-chain
  - _Requirements: 2.1, 3.1, 10.3_

- [ ]* 22.1 Write integration tests for data pipeline
  - Test metric fetching accuracy
  - Test oracle price synchronization
  - Test event listener functionality
  - _Requirements: 2.1, 3.1_

- [ ] 23. Implement monitoring and alerting
  - Create monitoring service for vault health
  - Implement alert triggers for anomalies
  - Add logging for all rebalancing operations
  - Create dashboard data endpoints
  - _Requirements: 9.3, 9.5_

- [ ] 24. Implement user interface (basic)
  - Create deposit UI component
  - Create withdrawal UI component
  - Create yield tracking dashboard
  - Create rebalancing history view
  - _Requirements: 1.1, 5.1, 6.4, 6.5_

- [ ]* 24.1 Write integration tests for UI flows
  - Test deposit flow end-to-end
  - Test withdrawal flow end-to-end
  - Test dashboard data accuracy
  - _Requirements: 1.1, 5.1_

- [ ] 25. Checkpoint - Ensure all tests pass (smart contracts + AI + integration)
  - Run all unit, property, and integration tests
  - Verify 100% test pass rate
  - Check end-to-end flows
  - Ask the user if questions arise

- [ ] 26. Deploy to Mantle testnet
  - Deploy vault contract to Mantle testnet
  - Deploy protocol adapters
  - Deploy oracle verifier
  - Verify contract deployments
  - Update configuration with deployed addresses
  - _Requirements: All_

- [ ] 27. End-to-end testing on testnet
  - Test user deposit flow
  - Test AI rebalancing proposal
  - Test oracle verification
  - Test rebalancing execution
  - Test user withdrawal
  - Verify yield accrual
  - _Requirements: All_

- [ ] 28. Final Checkpoint - Ensure all tests pass and system is ready
  - Ensure all tests pass, ask the user if questions arise

