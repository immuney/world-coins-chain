# WorldCoins Smart Contract System

A simplified token factory system built on Foundry that allows users to create and claim ERC20 tokens with fixed parameters.

## 🌟 Features

- **Token Creation**: Users can create one ERC20 token per address
- **Fixed Token Parameters**: All tokens have standardized parameters:
  - Total Supply: 1,000,000 tokens
  - Creator Initial Amount: 5,000 tokens
  - Claim Amount: 50 tokens per user
  - No payment required for claims
- **Claim System**: Users can claim tokens from any created token (once per token)
- **Token Registry**: Factory tracks all created tokens and claim status

## 📁 Project Structure

```
world-coins-chain/
├── src/
│   ├── WorldCoinsFactory.sol     # Main factory contract
│   └── WorldCoinToken.sol        # ERC20 token implementation
├── test/
│   └── WorldCoinsFactory.t.sol   # Comprehensive test suite
├── script/
│   ├── Deploy.s.sol              # Production deployment script
│   └── DeployLocal.s.sol         # Local testing deployment script
└── foundry.toml                  # Foundry configuration
```

## 🔧 Smart Contracts

### WorldCoinsFactory

The main factory contract that manages token creation and claims.

**Key Functions:**
- `createToken(TokenParams)` - Create a new token (one per user)
- `claimTokens(address tokenAddress)` - Claim tokens (once per token per user)
- `getAllTokens()` - Get all created token addresses
- `getTokenDetails(address)` - Get detailed token information
- `getClaimStats(address)` - Get claim statistics for a token

### WorldCoinToken

Standard ERC20 token with fixed parameters and factory integration.

**Fixed Parameters:**
- MAX_SUPPLY: 1,000,000 tokens
- CREATOR_INITIAL_AMOUNT: 5,000 tokens
- CLAIM_AMOUNT: 50 tokens per claim

## 🚀 Usage

### Building & Testing

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run specific tests
forge test --match-test "test_CreateToken"

# Run with gas reporting
forge test --gas-report
```

### Local Deployment

```bash
# Deploy locally for testing
forge script script/DeployLocal.s.sol

# Deploy to network (requires environment variables)
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast --verify
```

### Environment Variables

For production deployment, create a `.env` file:

```bash
PRIVATE_KEY=your_private_key_here
```

## 📊 Contract Usage Examples

### Creating a Token

```solidity
WorldCoinsFactory.TokenParams memory params = WorldCoinsFactory.TokenParams({
    name: "MyToken",
    symbol: "MTK",
    description: "My awesome token"
});

address tokenAddress = factory.createToken(params);
```

### Claiming Tokens

```solidity
// Any user can claim 50 tokens from any token (once per token)
factory.claimTokens(tokenAddress);
```

### Getting Token Information

```solidity
// Get all tokens
address[] memory allTokens = factory.getAllTokens();

// Get token details
(
    string memory name,
    string memory symbol,
    uint256 totalSupply,
    uint256 maxSupply,
    uint256 claimAmount,
    address creator,
    string memory description
) = factory.getTokenDetails(tokenAddress);

// Get claim statistics
(
    uint256 claimers,
    uint256 totalClaimed,
    uint256 availableSupply
) = factory.getClaimStats(tokenAddress);
```

## 🔍 Key Features

1. **One Token Per User**: Each address can only create one token
2. **Free Claims**: No payment required to claim tokens
3. **Fixed Economics**: All tokens have the same economic parameters
4. **Gas Efficient**: Optimized for low gas consumption
5. **Comprehensive Testing**: Full test coverage including fuzz testing
6. **Factory Pattern**: Centralized management of all tokens

## 🛡️ Security Features

- ReentrancyGuard on all state-changing functions
- Proper access controls using OpenZeppelin's Ownable
- Input validation for all parameters
- Safe arithmetic operations (Solidity 0.8.20+)
- Comprehensive error handling

## 📈 Testing

The project includes comprehensive tests covering:
- Token creation and validation
- Claim functionality and restrictions
- Edge cases and error conditions
- Fuzz testing for robustness
- Gas optimization verification

Run the full test suite with:
```bash
forge test -vvv
```

## 🔗 Integration

The factory contract provides all necessary functions for backend integration:
- Token creation verification
- Claim status checking
- Token registry management
- Detailed token information retrieval

Perfect for integration with web applications and APIs that need to manage token creation and claims.

## 📝 License

MIT License - see LICENSE file for details.
