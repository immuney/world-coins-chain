'use client'

import { MiniKitProvider } from '@worldcoin/minikit-js/minikit-provider'
import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createConfig, http } from 'wagmi'
import { worldchainSepolia } from 'wagmi/chains'
import { metaMask, walletConnect } from 'wagmi/connectors'
import { type ReactNode } from 'react'

// Create wagmi config with native World Chain Sepolia support
const wagmiConfig = createConfig({
  chains: [worldchainSepolia],
  connectors: [
    metaMask(),
  ],
  transports: {
    [worldchainSepolia.id]: http(process.env.NEXT_PUBLIC_WORLD_CHAIN_RPC_URL || 'https://worldchain-sepolia.g.alchemy.com/public'),
  },
})

// Create query client
const queryClient = new QueryClient()

export function Providers(props: {
  children: ReactNode
}) {
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <MiniKitProvider>
          {props.children}
        </MiniKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}
