# WorldCoins API Setup Guide

## Environment Variables

Create a `.env.local` file in the `miniapp` directory with the following variables:

```bash
# World ID Configuration
APP_ID=app_staging_xxx  # Your World ID app ID from dev.world.org
NEXT_PUBLIC_ACTION_ID=worldcoins-verify  # Action ID for World ID verification

# Contract Configuration  
NEXT_PUBLIC_FACTORY_ADDRESS=0x...  # WorldCoinsFactory contract address on World Chain Sepolia
FACTORY_ADDRESS=0x...  # Same as above, for server-side usage
FACTORY_PRIVATE_KEY=0x...  # Private key for factory operations (keep secret!)

# World Chain Sepolia Configuration
NEXT_PUBLIC_CHAIN_ID=4801
NEXT_PUBLIC_RPC_URL=https://worldchain-sepolia.g.alchemy.com/public

# Optional: Custom RPC URLs
WORLD_CHAIN_RPC_URL=https://worldchain-sepolia.g.alchemy.com/public
ALCHEMY_API_KEY=your_alchemy_api_key  # If using Alchemy

# Next.js
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your_nextauth_secret_here
```

## API Routes

### 1. `/api/verify-and-mint` (POST)
Creates a new token after World ID verification.

**Request Body:**
```json
{
  "payload": "...",  // World ID payload
  "action": "worldcoins-create",
  "signal": "user_address",
  "tokenParams": {
    "name": "My Token",
    "symbol": "MTK", 
    "description": "A cool token"
  },
  "userAddress": "0x..."
}
```

**Response:**
```json
{
  "success": true,
  "transactionHash": "0x...",
  "blockNumber": 12345,
  "tokenParams": {...}
}
```

### 2. `/api/verify-and-claim` (POST)
Claims tokens from an existing token after World ID verification.

**Request Body:**
```json
{
  "payload": "...",  // World ID payload
  "action": "worldcoins-claim",
  "signal": "user_address-token_address",
  "tokenAddress": "0x...",
  "userAddress": "0x..."
}
```

**Response:**
```json
{
  "success": true,
  "transactionHash": "0x...",
  "blockNumber": 12345,
  "claimAmount": "50"
}
```

### 3. `/api/tokens` (GET)
Retrieves all tokens from the factory.

**Response:**
```json
{
  "success": true,
  "tokens": [
    {
      "address": "0x...",
      "name": "My Token",
      "symbol": "MTK",
      "totalSupply": "5000",
      "maxSupply": "1000000",
      "claimAmount": "50",
      "creator": "0x...",
      "description": "A cool token",
      "claimStats": {
        "claimers": "3",
        "totalClaimed": "150",
        "availableSupply": "999850"
      }
    }
  ],
  "count": 1
}
```

### 4. `/api/tokens` (POST)
Retrieves filtered tokens for a specific user.

**Request Body:**
```json
{
  "userAddress": "0x...",  // Get tokens user has claimed/created
  "creatorAddress": "0x..."  // Get token created by specific address
}
```

## World Chain Sepolia Network Details

- **Chain ID:** 4801 (0x12C1)
- **RPC URL:** https://worldchain-sepolia.g.alchemy.com/public
- **Block Explorer:** https://worldchain-sepolia.explorer.alchemy.com
- **Native Currency:** ETH

## Contract Integration

The app uses the `WorldCoinsFactory` contract deployed on World Chain Sepolia. Key functions:

- `createToken(TokenParams)` - Creates a new token (1 per address)
- `claimTokens(address)` - Claims 50 tokens from a specific token
- `getAllTokens()` - Returns all token addresses
- `getTokenDetails(address)` - Returns token information
- `hasUserClaimed(user, token)` - Checks if user has claimed from token

## Setup Steps

1. **Deploy Contracts:** Use the `world-coins-chain` project to deploy the factory contract
2. **Get World ID App:** Register at dev.world.org and create an app
3. **Set Environment Variables:** Configure all required variables in `.env.local`
4. **Fund Factory Account:** Ensure the factory private key account has ETH for gas
5. **Run Development Server:** `npm run dev`

## Security Notes

- Keep `FACTORY_PRIVATE_KEY` secure and never commit it to version control
- Use different keys for testnet and mainnet deployments
- Consider using a hardware wallet or secure key management for production
- The factory account will pay for all token creation and claiming transactions

## World ID Actions

Configure these actions in your World ID app:

1. **worldcoins-verify** - Basic verification
2. **worldcoins-create** - Token creation
3. **worldcoins-claim** - Token claiming

Each action should have appropriate verification levels and rate limits configured in the World ID developer portal. 