# WorldCoins Hackathon MVP

## 1. Core Concept
- **One-person, one-claim memecoin** on World Chain, gated by World ID.
- Users pay **1 WLD** to claim **100 WLC** (WorldCoins).
- Fully deterministic—no gambling or chance.
- Everything happens on World Chain natively.

## 2. Architecture

### A. Monorepo Layout  
```
worldcoins/
├─ contracts/          # Smart contracts for World Chain
├─ miniapp/           # Next.js + wagmi + RainbowKit + @worldcoin/minikit-react
├─ .env.example       # WORLD_CHAIN_RPC_URL, PRIVATE_KEY, WLD_ADDRESS, UNISWAP_FACTORY_ADDRESS
└─ README.md          # Overview of setup and deployment
```

### B. Smart Contracts (contracts/)
- Simple Foundry project with `WorldCoinsFactory.sol` inheriting from `ERC20`.
- Constructor: `(address wldToken, address worldIdRouter)`  
  - Sets `IERC20 public immutable WLD = IERC20(wldToken)`  
  - Sets `IWorldID public immutable worldId = IWorldID(worldIdRouter)`
  - Initializes ERC-20 name "WorldCoins", symbol "WLC".
- State: 
  ```solidity
  mapping(uint256 => bool) public nullifierHashes; // World ID nullifiers
  uint256 internal immutable externalNullifier;
  uint256 internal immutable groupId = 1; // Orb verification
  ```
- `function claim(address signal, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)`:
  ```solidity
  require(!nullifierHashes[nullifierHash], "Already claimed");
  
  // Verify World ID proof
  worldId.verifyProof(
      root,
      groupId,
      abi.encodePacked(signal).hashToField(),
      nullifierHash,
      externalNullifier,
      proof
  );
  
  // Take payment
  require(WLD.transferFrom(msg.sender, address(this), 1 ether), "WLD payment failed");
  
  // Mark as claimed and mint
  nullifierHashes[nullifierHash] = true;
  _mint(msg.sender, 100 * 10**decimals());
  ```

**Foundry tests:**
- First claim with valid World ID → succeeds, mints 100 WLC.
- Double-claim with same nullifier → reverts "Already claimed".
- Invalid World ID proof → reverts from worldId.verifyProof().
- Insufficient WLD approval → reverts "WLD payment failed".

### C. Liquidity (Manual LP on World Chain)
- Deploy a Uniswap V3 pool on World Chain: WLC ↔ USDC, fee tier 0.3%, initial 1:1 price.
- Seed with a small % of total supply + matching USDC.
- Deep-link from miniapp:
  ```
  https://app.uniswap.org/#/swap?outputCurrency=<WLC>&chain=worldchain
  ```

### D. Mini App (miniapp/)
- Scaffold with `npm create wagmi@latest miniapp`.
- Install `@rainbow-me/rainbowkit`, `wagmi`, `@worldcoin/minikit-js`.
- Configure for World Chain network.

**UI flow:**
1. **Connect Wallet** (RainbowKit with World Chain)
2. **Verify World ID** 
   ```js
   import { IDKitWidget } from '@worldcoin/idkit'
   
   <IDKitWidget
     app_id="your_app_id"
     action="worldcoins-claim" 
     signal={userAddress}
     onSuccess={handleVerify}
     verification_level="orb"
   >
     {({ open }) => <button onClick={open}>Verify with World ID</button>}
   </IDKitWidget>
   ```
3. **Claim** → calls `WorldCoinsFactory.claim()` with World ID proof (1 WLD → 100 WLC)
4. **Success** → Show toast + transaction link
5. **Trade** → Deep-link to Uniswap pool on World Chain

**Features:**
- Display estimated gas cost (free with World Chain gas allowance for humans)
- Show WLD balance and approval status
- Transaction status tracking

## 3. Timeline & Scope
**Solo, ~15h build:**
- Contract logic & tests (4h)
- Foundry deploy scripts for World Chain (2h) 
- Pool deploy & seeding on World Chain (2h)
- Mini App UI & World ID integration (5h)
- E2E testing & polish (2h)

## 4. World Chain Advantages
- **Free gas for verified humans** - no gas costs for users
- **Native WLD token** - no bridging required
- **World ID Router** already deployed
- **Mini App distribution** via World App
- **Seamless UX** for World App users








You said:
ok write in exportable markdown


ChatGPT said:

Thought for 11 seconds
markdown
Copy
Edit
# WorldCoins Hackathon MVP

## 1. Core Concept
- **One-person, one-claim memecoin** on World Chain, gated by World ID.
- Users pay **1 WLD** to claim **100 WLC** (WorldCoins).
- Fully deterministic—no gambling or chance.
- Everything happens on World Chain natively.

## 2. Architecture

### A. Monorepo Layout  
worldcoins/
├─ contracts/          # Smart contracts for World Chain
├─ miniapp/           # Next.js + wagmi + RainbowKit + @worldcoin/minikit-react
├─ .env.example       # WORLD_CHAIN_RPC_URL, PRIVATE_KEY, WLD_ADDRESS, UNISWAP_FACTORY_ADDRESS
└─ README.md          # Overview of setup and deployment
```

### B. Smart Contracts (contracts/)
- Simple Foundry project with `WorldCoinsFactory.sol` inheriting from `ERC20`.
- Constructor: `(address wldToken, address worldIdRouter)`  
  - Sets `IERC20 public immutable WLD = IERC20(wldToken)`  
  - Sets `IWorldID public immutable worldId = IWorldID(worldIdRouter)`
  - Initializes ERC-20 name "WorldCoins", symbol "WLC".
- State: 
  ```solidity
  mapping(uint256 => bool) public nullifierHashes; // World ID nullifiers
  uint256 internal immutable externalNullifier;
  uint256 internal immutable groupId = 1; // Orb verification
  ```
- `function claim(address signal, uint256 root, uint256 nullifierHash, uint256[8] calldata proof)`:
  ```solidity
  require(!nullifierHashes[nullifierHash], "Already claimed");
  
  // Verify World ID proof
  worldId.verifyProof(
      root,
      groupId,
      abi.encodePacked(signal).hashToField(),
      nullifierHash,
      externalNullifier,
      proof
  );
  
  // Take payment
  require(WLD.transferFrom(msg.sender, address(this), 1 ether), "WLD payment failed");
  
  // Mark as claimed and mint
  nullifierHashes[nullifierHash] = true;
  _mint(msg.sender, 100 * 10**decimals());
  ```

**Foundry tests:**
- First claim with valid World ID → succeeds, mints 100 WLC.
- Double-claim with same nullifier → reverts "Already claimed".
- Invalid World ID proof → reverts from worldId.verifyProof().
- Insufficient WLD approval → reverts "WLD payment failed".

### C. Liquidity (Manual LP on World Chain)
- Deploy a Uniswap V3 pool on World Chain: WLC ↔ USDC, fee tier 0.3%, initial 1:1 price.
- Seed with a small % of total supply + matching USDC.
- Deep-link from miniapp:
  ```
  https://app.uniswap.org/#/swap?outputCurrency=<WLC>&chain=worldchain
  ```

### D. Mini App (miniapp/)
- Scaffold with `npm create wagmi@latest miniapp`.
- Install `@rainbow-me/rainbowkit`, `wagmi`, `@worldcoin/minikit-js`.
- Configure for World Chain network.

**UI flow:**
1. **Connect Wallet** (RainbowKit with World Chain)
2. **Verify World ID** 
   ```js
   import { IDKitWidget } from '@worldcoin/idkit'
   
   <IDKitWidget
     app_id="your_app_id"
     action="worldcoins-claim" 
     signal={userAddress}
     onSuccess={handleVerify}
     verification_level="orb"
   >
     {({ open }) => <button onClick={open}>Verify with World ID</button>}
   </IDKitWidget>
   ```
3. **Claim** → calls `WorldCoinsFactory.claim()` with World ID proof (1 WLD → 100 WLC)
4. **Success** → Show toast + transaction link
5. **Trade** → Deep-link to Uniswap pool on World Chain

**Features:**
- Display estimated gas cost (free with World Chain gas allowance for humans)
- Show WLD balance and approval status
- Transaction status tracking

## 3. Timeline & Scope
**Solo, ~15h build:**
- Contract logic & tests (4h)
- Foundry deploy scripts for World Chain (2h) 
- Pool deploy & seeding on World Chain (2h)
- Mini App UI & World ID integration (5h)
- E2E testing & polish (2h)

## 4. World Chain Advantages
- **Free gas for verified humans** - no gas costs for users
- **Native WLD token** - no bridging required
- **World ID Router** already deployed
- **Mini App distribution** via World App
- **Seamless UX** for World App users