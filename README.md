# Yieldra - AI-Assisted Yield Optimization Vault

An AI-assisted yield optimization vault on the Mantle Network that uses oracle-verified on-chain logic to safely rebalance assets across DeFi and RWA protocols.

## Core Principle

> **AI proposes. Oracles verify. Smart contracts decide.**

## Features

- **AI-Powered Rebalancing**: ElizaOS agent analyzes protocol metrics and proposes optimal allocations
- **Oracle Verification**: Pyth Network price feeds verify market conditions before execution
- **Multi-Protocol Support**: Allocate across Ondo Finance (USDY), Ethena (USDe), and Aave V3 (aUSDC)
- **Safety First**: Smart contracts enforce allocation constraints and volatility gates
- **Yield Tracking**: Real-time yield calculation and historical performance tracking

## Project Structure

```
yieldra/
├── src/
│   ├── interfaces/          # Smart contract interfaces
│   ├── abstracts/           # Abstract base contracts
│   ├── contracts/           # Main implementation contracts
│   └── libraries/           # Utility libraries
├── test/
│   ├── unit/               # Unit tests
│   ├── property/           # Property-based tests
│   └── integration/        # Integration tests
├── script/                 # Deployment scripts
├── .kiro/specs/yieldra/    # Spec documents
│   ├── requirements.md     # Feature requirements
│   ├── design.md          # System design
│   └── tasks.md           # Implementation tasks
└── foundry.toml           # Foundry configuration
```

## Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (for AI agent)
- [Python](https://www.python.org/) (for scripts)

### Installation

```bash
# Clone the repository
git clone https://github.com/dimka90/Yieldra.git
cd Yieldra

# Install Foundry dependencies
forge install

# Copy environment file
cp .env.example .env

# Update .env with your configuration
```

### Configuration

Update `.env` with:
- `MANTLE_RPC_URL`: Mantle Network RPC endpoint
- `PRIVATE_KEY`: Your deployment private key
- `ETHERSCAN_API_KEY`: For contract verification
- Protocol addresses for Mantle Network

## Development

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test file
forge test --match-path "test/unit/*"

# Run property-based tests
forge test --match-path "test/property/*"
```

### Format

```bash
forge fmt
```

## Deployment

### Testnet

```bash
# Deploy to Mantle testnet
forge script script/Deploy.s.sol --rpc-url mantle_testnet --broadcast
```

### Mainnet

```bash
# Deploy to Mantle mainnet
forge script script/Deploy.s.sol --rpc-url mantle --broadcast
```

## Architecture

### Smart Contracts

- **YieldraVault**: Main vault contract managing deposits, withdrawals, and rebalancing
- **ProtocolAdapters**: Adapters for Ondo, Ethena, and Aave V3
- **OracleVerifier**: Pyth oracle integration for price verification
- **StateManager**: State persistence and audit trail

### AI Agent

- **MetricsAnalyzer**: Fetches and analyzes protocol metrics
- **AllocationOptimizer**: Calculates optimal allocations
- **DecisionMemory**: Tracks past decisions and outcomes
- **ProposalExecutor**: Submits rebalancing proposals to vault

## Testing Strategy

### Unit Tests

Verify specific examples and edge cases for each component.

### Property-Based Tests

Verify universal properties that should hold across all inputs:

1. **Deposit Share Minting Consistency**: shares = deposit / sharePrice
2. **Allocation Constraint Enforcement**: 10% ≤ allocation ≤ 60%
3. **Volatility Gate Protection**: Reject if volatility ≥ 5%
4. **Fund Conservation**: Total value preserved during rebalancing
5. **Withdrawal Accuracy**: Withdrawal amount = shares × sharePrice
6. **Share Price Monotonicity**: Share price never decreases (unless loss)
7. **Allocation Tolerance**: Final allocation within 1% of target
8. **Oracle Price Freshness**: Prices < 60 seconds old
9. **Share Balance Consistency**: Sum of user shares = total shares
10. **Rebalance Idempotence**: Same proposal produces same result

### Integration Tests

Verify end-to-end flows:
- Deposit → Allocation
- Rebalance → Execution
- Withdrawal → Fund Recovery
- Oracle → Safety Gate

## Specification

See `.kiro/specs/yieldra/` for detailed documentation:

- **requirements.md**: Feature requirements with acceptance criteria
- **design.md**: System architecture and design decisions
- **tasks.md**: Implementation task list

## License

MIT

## Contributing

This project is developed for the Mantle Global Hackathon 2025 AI track.

## Support

For questions or issues, please open a GitHub issue.
