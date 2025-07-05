import { NextRequest, NextResponse } from "next/server";
import {
  verifyCloudProof,
  IVerifyResponse,
  ISuccessResult,
} from "@worldcoin/minikit-js";
import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { worldchainSepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// World Chain Sepolia configuration
const worldChainSepolia = {
  id: 4801,
  name: 'World Chain Sepolia',
  network: 'worldchain-sepolia',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    public: { http: ['https://worldchain-sepolia.g.alchemy.com/public'] },
    default: { http: ['https://worldchain-sepolia.g.alchemy.com/public'] },
  },
  blockExplorers: {
    default: { name: 'World Chain Sepolia Explorer', url: 'https://worldchain-sepolia.explorer.alchemy.com' },
  },
  testnet: true,
} as const;

// WorldCoinsFactory ABI (minimal for createToken function)
const FACTORY_ABI = [
  {
    "inputs": [
      {
        "components": [
          { "internalType": "string", "name": "name", "type": "string" },
          { "internalType": "string", "name": "symbol", "type": "string" },
          { "internalType": "string", "name": "description", "type": "string" }
        ],
        "internalType": "struct WorldCoinsFactory.TokenParams",
        "name": "params",
        "type": "tuple"
      }
    ],
    "name": "createToken",
    "outputs": [{ "internalType": "address", "name": "tokenAddress", "type": "address" }],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{ "internalType": "address", "name": "", "type": "address" }],
    "name": "hasCreatedToken",
    "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }],
    "stateMutability": "view",
    "type": "function"
  }
] as const;

interface IRequestPayload {
  payload: ISuccessResult;
  action: string;
  signal?: string;
  tokenParams: {
    name: string;
    symbol: string;
    description: string;
  };
  userAddress: string;
}

export async function POST(req: NextRequest) {
  try {
    const { payload, action, signal, tokenParams, userAddress } = (await req.json()) as IRequestPayload;
    const app_id = process.env.APP_ID as `app_${string}`;
    const factory_address = process.env.FACTORY_ADDRESS as `0x${string}`;
    let private_key = process.env.FACTORY_PRIVATE_KEY;
    
    if (!app_id) {
      return NextResponse.json({
        status: 500,
        error: "World ID app ID not configured. Please set APP_ID in .env.local",
      });
    }

    if (!factory_address) {
      return NextResponse.json({
        status: 500,
        error: "Factory contract address not configured. Please set FACTORY_ADDRESS in .env.local",
      });
    }

    if (!private_key) {
      return NextResponse.json({
        status: 500,
        error: "Factory private key not configured. Please set FACTORY_PRIVATE_KEY in .env.local",
      });
    }

    // Ensure private key is properly formatted
    if (!private_key.startsWith('0x')) {
      private_key = `0x${private_key}`;
    }
    
    // Validate private key format (should be 64 hex characters + 0x prefix)
    if (!/^0x[a-fA-F0-9]{64}$/.test(private_key)) {
      return NextResponse.json({
        status: 500,
        error: "Invalid private key format. Must be 64 hex characters with 0x prefix",
      });
    }

    const formattedPrivateKey = private_key as `0x${string}`;

    // Verify World ID proof first
    const verifyRes = (await verifyCloudProof(
      payload,
      app_id,
      action,
      signal
    )) as IVerifyResponse;

    if (!verifyRes.success) {
      return NextResponse.json({ 
        error: "World ID verification failed",
        verifyRes, 
        status: 400 
      });
    }

    // Set up viem clients for World Chain Sepolia
    const publicClient = createPublicClient({
      chain: worldChainSepolia,
      transport: http(),
    });

    const account = privateKeyToAccount(formattedPrivateKey);
    const walletClient = createWalletClient({
      account,
      chain: worldChainSepolia,
      transport: http(),
    });

    // Check if user has already created a token
    const hasCreated = await publicClient.readContract({
      address: factory_address,
      abi: FACTORY_ABI,
      functionName: 'hasCreatedToken',
      args: [userAddress as `0x${string}`],
    });

    if (hasCreated) {
      return NextResponse.json({
        status: 400,
        error: "User has already created a token",
      });
    }

    // Validate token parameters
    if (!tokenParams.name || !tokenParams.symbol) {
      return NextResponse.json({
        status: 400,
        error: "Token name and symbol are required",
      });
    }

    // Create the token
    try {
      const hash = await walletClient.writeContract({
        address: factory_address,
        abi: FACTORY_ABI,
        functionName: 'createToken',
        args: [tokenParams],
      });

      // Wait for transaction confirmation
      const receipt = await publicClient.waitForTransactionReceipt({ 
        hash,
        timeout: 60_000, // 60 seconds timeout
      });

      // Extract token address from logs if needed
      console.log('Token created successfully:', {
        transactionHash: hash,
        blockNumber: receipt.blockNumber,
        gasUsed: receipt.gasUsed,
      });

      return NextResponse.json({ 
        success: true,
        verifyRes,
        transactionHash: hash,
        blockNumber: receipt.blockNumber,
        tokenParams,
        status: 200 
      });

    } catch (contractError) {
      console.error("Contract interaction error:", contractError);
      return NextResponse.json({
        status: 500,
        error: "Failed to create token on contract",
        details: contractError instanceof Error ? contractError.message : "Unknown contract error",
      });
    }

  } catch (error) {
    console.error("Error in verify-and-mint:", error);
    return NextResponse.json({
      status: 500,
      error: error instanceof Error ? error.message : "Unknown error occurred",
    });
  }
} 