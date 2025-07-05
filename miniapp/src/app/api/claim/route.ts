import { NextRequest, NextResponse } from "next/server";
import { MiniKit } from "@worldcoin/minikit-js";

interface IClaimRequest {
  address: string;
  verificationProof?: any; // World ID verification proof
}

export async function POST(req: NextRequest) {
  try {
    const { address, verificationProof } = (await req.json()) as IClaimRequest;
    
    if (!address) {
      return NextResponse.json({
        status: 400,
        error: "Address is required",
      });
    }

    // Here you would:
    // 1. Verify the user has been verified with World ID
    // 2. Check if they have already claimed
    // 3. Prepare the transaction for the WorldCoinsFactory contract
    
    // For now, return the transaction data that the frontend can use
    // The actual transaction will be sent through MiniKit.commandsAsync.sendTransaction
    
    const contractAddress = process.env.WORLDCOINS_FACTORY_ADDRESS;
    if (!contractAddress) {
      return NextResponse.json({
        status: 500,
        error: "Contract address not configured",
      });
    }

    // Return transaction data
    return NextResponse.json({
      success: true,
      transaction: {
        to: contractAddress,
        data: "0x4e71d92d", // claim() function selector
        value: "0x0", // No ETH value needed
      },
    });
  } catch (error) {
    console.error("Error preparing claim transaction:", error);
    return NextResponse.json({
      status: 500,
      error: error instanceof Error ? error.message : "Unknown error occurred",
    });
  }
} 