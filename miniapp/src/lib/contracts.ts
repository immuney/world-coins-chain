import { createPublicClient, createWalletClient, http, custom, parseEther, formatEther } from 'viem'
import { worldchainSepolia } from 'viem/chains'
import WorldCoinsFactoryABI from '../abis/WorldCoinsFactory.json'
import WorldCoinTokenABI from '../abis/WorldCoinToken.json'

// Contract addresses - these should be set after deployment
export const FACTORY_ADDRESS = process.env.NEXT_PUBLIC_FACTORY_ADDRESS as `0x${string}`
export const WORLD_CHAIN_RPC_URL = process.env.NEXT_PUBLIC_WORLD_CHAIN_RPC_URL || 'https://worldchain-sepolia.g.alchemy.com/public'

// Create public client for reading blockchain data
export const publicClient = createPublicClient({
  chain: worldchainSepolia,
  transport: http(WORLD_CHAIN_RPC_URL),
})

// Create wallet client for transactions
export const createWalletClientForSigner = (signer: any) => {
  return createWalletClient({
    chain: worldchainSepolia,
    transport: custom(signer),
  })
}

// Factory contract functions
export const factoryContract = {
  address: FACTORY_ADDRESS,
  abi: WorldCoinsFactoryABI.abi,
} as const

export const tokenContract = {
  abi: WorldCoinTokenABI.abi,
} as const

// Helper functions for contract interactions
export const contractHelpers = {
  // Get all tokens created by the factory
  async getAllTokens() {
    try {
      const tokens = await publicClient.readContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'getAllTokens',
      })
      return tokens as `0x${string}`[]
    } catch (error) {
      console.error('Error fetching tokens:', error)
      return []
    }
  },

  // Get token details
  async getTokenDetails(tokenAddress: `0x${string}`) {
    try {
      const details = await publicClient.readContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'getTokenDetails',
        args: [tokenAddress],
      })
      return details as [string, string, bigint, bigint, bigint, `0x${string}`, string]
    } catch (error) {
      console.error('Error fetching token details:', error)
      return null
    }
  },

  // Get claim statistics for a token
  async getClaimStats(tokenAddress: `0x${string}`) {
    try {
      const stats = await publicClient.readContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'getClaimStats',
        args: [tokenAddress],
      })
      return stats as [bigint, bigint, bigint]
    } catch (error) {
      console.error('Error fetching claim stats:', error)
      return null
    }
  },

  // Check if user has claimed from a token
  async hasUserClaimed(userAddress: `0x${string}`, tokenAddress: `0x${string}`) {
    try {
      const hasClaimed = await publicClient.readContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'hasUserClaimed',
        args: [userAddress, tokenAddress],
      })
      return hasClaimed as boolean
    } catch (error) {
      console.error('Error checking claim status:', error)
      return false
    }
  },

  // Check if user has created a token
  async hasCreatedToken(userAddress: `0x${string}`) {
    try {
      const hasCreated = await publicClient.readContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'hasCreatedToken',
        args: [userAddress],
      })
      return hasCreated as boolean
    } catch (error) {
      console.error('Error checking creation status:', error)
      return false
    }
  },

  // Get token created by user
  async getTokenByCreator(creatorAddress: `0x${string}`) {
    try {
      const tokenAddress = await publicClient.readContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'getTokenByCreator',
        args: [creatorAddress],
      })
      return tokenAddress as `0x${string}`
    } catch (error) {
      console.error('Error fetching token by creator:', error)
      return null
    }
  },

  // Get token balance
  async getTokenBalance(tokenAddress: `0x${string}`, userAddress: `0x${string}`) {
    try {
      const balance = await publicClient.readContract({
        address: tokenAddress,
        abi: WorldCoinTokenABI.abi,
        functionName: 'balanceOf',
        args: [userAddress],
      })
      return balance as bigint
         } catch (error) {
       console.error('Error fetching token balance:', error)
       return BigInt(0)
     }
  },

  // Create token (requires wallet client)
  async createToken(walletClient: any, params: { name: string; symbol: string; description: string }) {
    try {
      const hash = await walletClient.writeContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'createToken',
        args: [params],
      })
      return hash
    } catch (error) {
      console.error('Error creating token:', error)
      throw error
    }
  },

  // Claim tokens (requires wallet client)
  async claimTokens(walletClient: any, tokenAddress: `0x${string}`) {
    try {
      const hash = await walletClient.writeContract({
        address: FACTORY_ADDRESS,
        abi: WorldCoinsFactoryABI.abi,
        functionName: 'claimTokens',
        args: [tokenAddress],
      })
      return hash
    } catch (error) {
      console.error('Error claiming tokens:', error)
      throw error
    }
  },

  // Wait for transaction confirmation
  async waitForTransaction(hash: `0x${string}`) {
    try {
      const receipt = await publicClient.waitForTransactionReceipt({ hash })
      return receipt
    } catch (error) {
      console.error('Error waiting for transaction:', error)
      throw error
    }
  },

  // Format token amounts for display
  formatTokenAmount(amount: bigint, decimals: number = 18) {
    return formatEther(amount)
  },

  // Parse token amounts from user input
  parseTokenAmount(amount: string) {
    return parseEther(amount)
  },
}

export default contractHelpers 