import { http, createConfig } from '@wagmi/core'
import { worldchainSepolia } from 'viem/chains'


export const config = createConfig({
  chains: [worldchainSepolia],
  transports: {
    [worldchainSepolia.id]: http('https://worldchain-sepolia.g.alchemy.com/public'),
  },
})