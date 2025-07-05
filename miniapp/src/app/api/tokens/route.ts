import { NextRequest, NextResponse } from "next/server";
import { contractHelpers } from "@/lib/contracts";

interface TokenInfo {
  address: string
  name: string
  symbol: string
  totalSupply: string
  maxSupply: string
  claimAmount: string
  creator: string
  description: string
  claimStats: {
    claimers: string
    totalClaimed: string
    availableSupply: string
  }
}

export async function GET(req: NextRequest) {
  try {
    // Get all token addresses from the factory
    const tokenAddresses = await contractHelpers.getAllTokens();

    if (tokenAddresses.length === 0) {
      return NextResponse.json({
        success: true,
        data: [],
        count: 0
      });
    }
    
    // Fetch details for each token
    const tokensWithDetails = await Promise.all(
      tokenAddresses.map(async (address) => {
        try {
          const details = await contractHelpers.getTokenDetails(address);
          const claimStats = await contractHelpers.getClaimStats(address);
          
          if (!details || !claimStats) {
            return null;
          }
          
          const [name, symbol, totalSupply, maxSupply, claimAmount, creator, description] = details;
          const [claimers, totalClaimed, availableSupply] = claimStats;
          
          return {
            address,
            name,
            symbol,
            totalSupply: totalSupply.toString(),
            maxSupply: maxSupply.toString(),
            claimAmount: claimAmount.toString(),
            creator,
            description,
            claimStats: {
              claimers: claimers.toString(),
              totalClaimed: totalClaimed.toString(),
              availableSupply: availableSupply.toString(),
            }
          } as TokenInfo;
        } catch (error) {
          console.error(`Error fetching details for token ${address}:`, error);
          return null;
        }
      })
    );
    
    // Filter out null entries
    const validTokens = tokensWithDetails.filter(token => token !== null);
    
    return NextResponse.json({
      success: true,
      data: validTokens,
      count: validTokens.length
    });
  } catch (error) {
    console.error("Error fetching tokens:", error);
    return NextResponse.json(
      { 
        success: false, 
        error: "Failed to fetch tokens",
        details: error instanceof Error ? error.message : "Unknown error"
      },
      { status: 500 }
    );
  }
}

// Optional: Support query parameters for filtering or pagination
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { userAddress, creatorAddress } = body;
    
    if (userAddress) {
      // Get tokens where user has claimed or created
      const allTokens = await contractHelpers.getAllTokens();
      const userTokens = [];
      
      for (const tokenAddress of allTokens) {
        try {
          const [tokenDetails, hasClaimed, isCreator] = await Promise.all([
            contractHelpers.getTokenDetails(tokenAddress),
            contractHelpers.hasUserClaimed(userAddress as `0x${string}`, tokenAddress),
            tokenAddress === await contractHelpers.getTokenByCreator(userAddress as `0x${string}`).catch(() => null),
          ]);
          
          if (hasClaimed || isCreator) {
            const claimStats = await contractHelpers.getClaimStats(tokenAddress);
            const userBalance = await contractHelpers.getTokenBalance(
              tokenAddress, 
              userAddress as `0x${string}`
            );
            
            if (tokenDetails && claimStats) {
              const [name, symbol, totalSupply, maxSupply, claimAmount, creator, description] = tokenDetails;
              const [claimers, totalClaimed, availableSupply] = claimStats;
              
              userTokens.push({
                address: tokenAddress,
                name,
                symbol,
                totalSupply: totalSupply.toString(),
                maxSupply: maxSupply.toString(),
                claimAmount: claimAmount.toString(),
                creator,
                description,
                claimStats: {
                  claimers: claimers.toString(),
                  totalClaimed: totalClaimed.toString(),
                  availableSupply: availableSupply.toString(),
                },
                userBalance: userBalance.toString(),
                userHasClaimed: hasClaimed,
                userIsCreator: isCreator,
              });
            }
          }
        } catch (error) {
          console.error(`Error checking user tokens for ${tokenAddress}:`, error);
        }
      }
      
      return NextResponse.json({
        success: true,
        tokens: userTokens,
        count: userTokens.length,
      });
    }
    
    if (creatorAddress) {
      // Get token created by specific creator
      try {
        const tokenAddress = await contractHelpers.getTokenByCreator(creatorAddress as `0x${string}`);
        
        if (tokenAddress && tokenAddress !== '0x0000000000000000000000000000000000000000') {
          const [tokenDetails, claimStats] = await Promise.all([
            contractHelpers.getTokenDetails(tokenAddress),
            contractHelpers.getClaimStats(tokenAddress),
          ]);
          
          if (tokenDetails && claimStats) {
            const [name, symbol, totalSupply, maxSupply, claimAmount, creator, description] = tokenDetails;
            const [claimers, totalClaimed, availableSupply] = claimStats;
            
            return NextResponse.json({
              success: true,
              token: {
                address: tokenAddress,
                name,
                symbol,
                totalSupply: totalSupply.toString(),
                maxSupply: maxSupply.toString(),
                claimAmount: claimAmount.toString(),
                creator,
                description,
                claimStats: {
                  claimers: claimers.toString(),
                  totalClaimed: totalClaimed.toString(),
                  availableSupply: availableSupply.toString(),
                },
              },
            });
          }
        } else {
          return NextResponse.json({
            success: true,
            token: null,
            message: "No token created by this address",
          });
        }
      } catch (error) {
        console.error(`Error fetching token by creator ${creatorAddress}:`, error);
        return NextResponse.json({
          success: false,
          error: "Failed to fetch token by creator",
        }, { status: 500 });
      }
    }
    
    // Default to GET behavior if no specific filters
    return GET(req);
    
  } catch (error) {
    console.error("Error in POST /api/tokens:", error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error occurred",
    }, { status: 500 });
  }
} 