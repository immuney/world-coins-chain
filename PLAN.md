1. Core Concept
One-person, one-claim memecoin on Base, gated by World ID.

Users pay 1 WLD to claim 100 WLC tokens (WorldCoins).

Fully deterministic—no gambling or chance.

2. Architecture
A. Monorepo Layout
graphql
Copy
Edit
worldcoins/
├─ lz-app/        # LayerZero OApp template (pruned)
├─ miniapp/       # Next.js + wagmi + RainbowKit + @worldcoin/minikit-react
├─ .env.example   # BASE_RPC_URL, PRIVATE_KEY, WLD_ADDRESS, UNISWAP_FACTORY_ADDRESS, UNISWAP_POSITION_MANAGER_ADDRESS
└─ README.md
B. Contracts (under lz-app/)
Scaffold via npx create-lz-oapp@latest --example oapp .

Prune everything except the core OApp stub.

Rename MyOApp.sol → WorldCoinsFactory.sol, inheriting ERC20 & OApp.

Constructor takes (address endpoint, address wldToken), calls OApp(_endpoint, msg.sender) and Ownable(msg.sender), sets name/symbol (“WorldCoins”, “WLC”), and stores IERC20 public immutable WLD.

mapping(address=>bool) public hasClaimed;

function claim():

require(!hasClaimed[msg.sender], "Already claimed");

require(WLD.transferFrom(msg.sender, address(this), 1 ether), "WLD payment failed");

hasClaimed[msg.sender] = true;

_mint(msg.sender, 100 * 10**decimals());

Foundry/Forge tests covering:

First claim → succeeds, mints 100 WLC.

Double-claim → reverts “Already claimed”.

Insufficient WLD → reverts “WLD payment failed”.

C. Liquidity (Manual LP)
Deploy a UniswapV3 pool on Base: WLC ↔ USDC (or WETH) at 1:1 initial price, 0.3% fee tier.

Seed with a small % of total supply + matching USDC.

Deep-link from miniapp to the pool via https://app.uniswap.org/#/swap?outputCurrency=<WLC>&chain=base.

D. Mini App (under miniapp/)
Scaffold via npm create wagmi@latest miniapp.

Install @rainbow-me/rainbowkit, wagmi, ethers, @worldcoin/minikit-react.

UI flow:

Connect wallet (RainbowKit)

Verify World ID (useMiniKit().sendCommand("Verify", …))

Claim button → calls WorldCoinsFactory.claim() (pays 1 WLD + mints)

Show toast + transaction link

“Trade” button links to the Uniswap pool on Base

Display an estimated gas cost (~0.05 WLD) before submitting.

3. Timeline & Scope
Solo, ~20 h build:

Scaffold & prune (2 h)

Contract logic & tests (5 h)

Pool deploy & seeding (2 h)

Mini App UI & integration (6 h)

E2E testing, polish & recording (5 h)

You can take this spec into Cursor—or your editor of choice—and start implementing from here. Let me know when you’re ready for the first actionable step!








You said:
ok write in exportable markdown


ChatGPT said:

Thought for 11 seconds
markdown
Copy
Edit
# WorldCoins Hackathon MVP

## 1. Core Concept
- **One-person, one-claim memecoin** on Base, gated by World ID.
- Users pay **1 WLD** to claim **100 WLC** (WorldCoins).
- Fully deterministic—no gambling or chance.

## 2. Architecture

### A. Monorepo Layout  
worldcoins/
├─ lz-app/ # LayerZero OApp template (pruned)
├─ miniapp/ # Next.js + wagmi + RainbowKit + @worldcoin/minikit-react
├─ .env.example # BASE_RPC_URL, PRIVATE_KEY, WLD_ADDRESS,
│ # UNISWAP_FACTORY_ADDRESS, UNISWAP_POSITION_MANAGER_ADDRESS
└─ README.md # Overview of folders & env setup

markdown
Copy
Edit

### B. Contracts (lz-app/)
- Scaffold with `npx create-lz-oapp@latest --example oapp .` then delete extras.
- Rename `OApp.sol` → `WorldCoinsFactory.sol`, inheriting `ERC20` & `NonblockingLzApp`.
- Constructor: `(address endpoint, address wldToken)`  
  - Calls `NonblockingLzApp(endpoint)`  
  - Sets `IERC20 public immutable WLD = IERC20(wldToken)`  
  - Initializes ERC-20 name “WorldCoins”, symbol “WLC”.
- State: `mapping(address=>bool) public hasClaimed;`
- `function claim()`:
  ```solidity
    require(!hasClaimed[msg.sender], "Already claimed");
    require(WLD.transferFrom(msg.sender, address(this), 1 ether), "WLD payment failed");
    hasClaimed[msg.sender] = true;
    _mint(msg.sender, 100 * 10**decimals());
Forge tests:

First claim succeeds → mints 100 WLC.

Double-claim reverts “Already claimed”.

Insufficient/no WLD approval reverts “WLD payment failed”.

C. Liquidity (Manual LP)
Deploy a Uniswap V3 pool on Base: WLC ↔ USDC (or WETH), fee tier 0.3%, initial 1:1 price.

Seed with a small % of total supply + matching USDC.

Deep-link from miniapp:

bash
Copy
Edit
https://app.uniswap.org/#/swap?outputCurrency=<WLC>&chain=base
D. Mini App (miniapp/)
Scaffold with npm create wagmi@latest miniapp.

Install @rainbow-me/rainbowkit, wagmi, ethers, @worldcoin/minikit-react.

UI flow:

Connect Wallet (RainbowKit)

Verify World ID

js
Copy
Edit
useMiniKit().sendCommand("Verify", { action: "...", signal: "..." });
Claim → calls WorldCoinsFactory.claim() (1 WLD → 100 WLC)

Show success/failure toast & tx link

Trade button → deep-link to Uniswap pool on Base

Display estimated gas cost (≈ 0.05 WLD) pre-submit.