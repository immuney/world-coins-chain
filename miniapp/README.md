# WorldCoins MiniApp

A MiniApp for claiming WorldCoins (WLC) tokens using WorldCoin verification and wallet authentication.

## Features

- **World ID Verification**: Users must verify their World ID before claiming tokens
- **Wallet Authentication**: Secure wallet connection using WorldCoin's SIWE (Sign-In with Ethereum) 
- **Token Claiming**: Claim 100 WLC tokens by paying 1 WLD (one-time per address)
- **Backend Verification**: All verification and authentication is handled securely on the backend

## Setup

### 1. Environment Variables

Create a `.env.local` file in the root directory with the following variables:

```bash
# WorldCoin Configuration (backend only - never expose APP_ID to frontend)
# Get these from https://developer.worldcoin.org/
APP_ID=app_your_app_id_here
NEXT_PUBLIC_ACTION_ID=worldcoins-claim

# Smart Contract Configuration
WORLDCOINS_FACTORY_ADDRESS=0x...
```

### 2. WorldCoin Developer Setup

1. Go to [WorldCoin Developer Portal](https://developer.worldcoin.org/)
2. Create a new app
3. Copy your App ID and set it as `APP_ID` (backend only - never expose to frontend)
4. Create an action with ID `worldcoins-claim` or update the `NEXT_PUBLIC_ACTION_ID` accordingly

### 3. Smart Contract Deployment

Deploy the WorldCoinsFactory contract and set the `WORLDCOINS_FACTORY_ADDRESS` environment variable.

## API Routes

The app includes several API routes for secure backend verification:

- `/api/verify` - Verifies World ID proofs using WorldCoin's cloud verification
- `/api/nonce` - Generates secure nonces for wallet authentication
- `/api/complete-siwe` - Completes the Sign-In with Ethereum flow
- `/api/claim` - Prepares claim transactions for the smart contract

## Usage Flow

1. **Connect Wallet**: User connects their WorldCoin wallet
2. **Verify World ID**: User verifies their World ID through the WorldCoin app
3. **Claim Tokens**: User pays 1 WLD to claim 100 WLC tokens
4. **Trade**: User can trade WLC tokens on Uniswap

## Technical Details

### Frontend
- Built with Next.js 14 and React 18
- Uses `@worldcoin/minikit-js` for WorldCoin integration
- Tailwind CSS for styling
- Custom UI components
- Displays usernames instead of wallet addresses for better UX

### Backend
- Next.js API routes for secure verification
- WorldCoin cloud verification using APP_ID (never exposed to frontend)
- SIWE (Sign-In with Ethereum) implementation
- Secure cookie-based nonce management

### Smart Contract
- ERC20 token implementation (WLC)
- LayerZero integration for cross-chain functionality
- One-time claiming mechanism
- WLD payment requirement

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Security Considerations

- All WorldCoin verification is handled on the backend
- APP_ID is never exposed to the frontend (backend environment variable only)
- Nonces are securely generated and stored in HTTP-only cookies
- Smart contract prevents double-claiming
- Frontend validation is supplemented by backend verification

## Troubleshooting

### Common Issues

1. **"World App is not installed"** - Ensure you're running the app inside the WorldCoin app
2. **"Invalid nonce"** - Clear cookies and try again
3. **"Verification failed"** - Check your WorldCoin app configuration
4. **"Contract address not configured"** - Set the `WORLDCOINS_FACTORY_ADDRESS` environment variable
5. **"World ID app ID not configured"** - Set the `APP_ID` environment variable (backend only)

### Debug Mode

Enable debug logging by setting:
```bash
NODE_ENV=development
```
