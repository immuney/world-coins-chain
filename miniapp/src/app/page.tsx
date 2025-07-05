'use client'

import { useState, useEffect } from 'react'
import { MiniKit } from '@worldcoin/minikit-js'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

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

export default function WorldCoinsApp() {
  const [isVerified, setIsVerified] = useState(false)
  const [userAddress, setUserAddress] = useState<string>('')
  const [username, setUsername] = useState<string | null>(null)
  const [isWorldApp, setIsWorldApp] = useState<boolean | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  
  // Token creation states
  const [hasCreatedToken, setHasCreatedToken] = useState(false)
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [tokenForm, setTokenForm] = useState({
    name: '',
    symbol: '',
    description: ''
  })
  
  // Token listing states
  const [allTokens, setAllTokens] = useState<TokenInfo[]>([])
  const [loadingTokens, setLoadingTokens] = useState(false)

  useEffect(() => {
    const checkMiniKit = () => {
      const installed = MiniKit.isInstalled()
      console.log('MiniKit.isInstalled():', installed)
      setIsWorldApp(installed)
    }

    checkMiniKit()
    fetchAllTokens()
  }, [])

  const fetchAllTokens = async () => {
    setLoadingTokens(true)
    try {
      const response = await fetch('/api/tokens')
      const data = await response.json()
      if (data.success) {
        setAllTokens(data.data || [])
      }
    } catch (error) {
      console.error('Error fetching tokens:', error)
      setAllTokens([]) // Set empty array on error
    } finally {
      setLoadingTokens(false)
    }
  }

  const handleWalletAuth = async () => {
    if (isWorldApp === false) {
      alert('Please open this app inside World App')
      return
    }

    setIsLoading(true)
    setError(null)
    
    try {
      // Get nonce from backend
      const nonceResponse = await fetch('/api/nonce')
      const { nonce } = await nonceResponse.json()

      // Perform wallet auth with nonce
      const result = await MiniKit.commandsAsync.walletAuth({
        nonce,
        requestId: Math.random().toString(36).substring(7),
        expirationTime: new Date(Date.now() + 5 * 60 * 1000),
        notBefore: new Date(),
        statement: 'Connect your wallet to use WorldCoins',
      })

      if (result.finalPayload.status === 'error') {
        setError('Wallet connection failed')
        return
      }

      // Verify SIWE message on backend
      const verifyResponse = await fetch('/api/complete-siwe', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          payload: result.finalPayload,
          nonce,
        }),
      })

      const verifyResult = await verifyResponse.json()

      if (verifyResponse.ok && verifyResult.isValid) {
        setUserAddress(result.finalPayload.address)
        console.log('Wallet connected:', result.finalPayload.address)
        
        // Check if user has created a token
        try {
          const tokenResponse = await fetch('/api/tokens', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ creatorAddress: result.finalPayload.address })
          })
          const tokenData = await tokenResponse.json()
          setHasCreatedToken(!!tokenData.token)
        } catch (err) {
          console.error('Error checking user token:', err)
        }
        
        // Fetch username for better UX
        try {
          const userProfile = await MiniKit.getUserByAddress(result.finalPayload.address)
          setUsername(userProfile.username || null)
          console.log('Username fetched:', userProfile.username)
        } catch (usernameError) {
          console.log('Could not fetch username:', usernameError)
        }
      } else {
        setError('Wallet authentication failed')
        console.error('Wallet authentication failed:', verifyResult)
      }
    } catch (error) {
      console.error('Error connecting wallet:', error)
      setError('Error connecting wallet')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCreateToken = async () => {
    if (!isVerified || !userAddress || hasCreatedToken) {
      setError('Please verify with World ID first')
      return
    }

    if (!tokenForm.name || !tokenForm.symbol) {
      setError('Token name and symbol are required')
      return
    }

    setIsLoading(true)
    setError(null)
    
    try {
      // Get World ID verification
      const result = await MiniKit.commandsAsync.verify({
        action: process.env.NEXT_PUBLIC_ACTION_ID || 'worldcoins-create',
        signal: userAddress,
      })

      if (result.finalPayload.status === 'error') {
        setError('World ID verification failed')
        return
      }

      // Send to verify-and-mint API
      const response = await fetch('/api/verify-and-mint', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          payload: result.finalPayload,
          action: process.env.NEXT_PUBLIC_ACTION_ID || 'worldcoins-create',
          signal: userAddress,
          tokenParams: tokenForm,
          userAddress: userAddress,
        }),
      })

      const data = await response.json()

      if (response.ok && data.success) {
        setHasCreatedToken(true)
        setShowCreateForm(false)
        setTokenForm({ name: '', symbol: '', description: '' })
        await fetchAllTokens() // Refresh token list
        console.log('Token created successfully:', data)
      } else {
        setError(data.error || 'Failed to create token')
        console.error('Token creation failed:', data)
      }
    } catch (error) {
      console.error('Error creating token:', error)
      setError('Error creating token')
    } finally {
      setIsLoading(false)
    }
  }

  const handleClaimTokens = async (tokenAddress: string) => {
    if (!isVerified || !userAddress) {
      setError('Please verify with World ID first')
      return
    }

    setIsLoading(true)
    setError(null)
    
    try {
      // Get World ID verification
      const result = await MiniKit.commandsAsync.verify({
        action: process.env.NEXT_PUBLIC_ACTION_ID || 'worldcoins-claim',
        signal: `${userAddress}-${tokenAddress}`,
      })

      if (result.finalPayload.status === 'error') {
        setError('World ID verification failed')
        return
      }

      // Send to verify-and-claim API
      const response = await fetch('/api/verify-and-claim', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          payload: result.finalPayload,
          action: process.env.NEXT_PUBLIC_ACTION_ID || 'worldcoins-claim',
          signal: `${userAddress}-${tokenAddress}`,
          tokenAddress: tokenAddress,
          userAddress: userAddress,
        }),
      })

      const data = await response.json()

      if (response.ok && data.success) {
        await fetchAllTokens() // Refresh token list
        console.log('Tokens claimed successfully:', data)
      } else {
        setError(data.error || 'Failed to claim tokens')
        console.error('Token claim failed:', data)
      }
    } catch (error) {
      console.error('Error claiming tokens:', error)
      setError('Error claiming tokens')
    } finally {
      setIsLoading(false)
    }
  }

  const handleVerifyWorldID = async () => {
    if (isWorldApp === false) {
      alert('Please open this app inside World App')
      return
    }

    setIsLoading(true)
    setError(null)
    
    try {
      const result = await MiniKit.commandsAsync.verify({
        action: process.env.NEXT_PUBLIC_ACTION_ID || 'worldcoins-verify',
        signal: userAddress || 'worldcoins-verification',
      })

      if (result.finalPayload.status === 'error') {
        setError('World ID verification failed')
        return
      }

      // Just verify without any backend action for now
      setIsVerified(true)
      console.log('World ID verified successfully')

    } catch (error) {
      console.error('Error verifying World ID:', error)
      setError('Error verifying World ID')
    } finally {
      setIsLoading(false)
    }
  }

  if (isWorldApp === null) {
    return (
      <div className="container mx-auto p-4">
        <Card className="max-w-md mx-auto">
          <CardHeader>
            <CardTitle>WorldCoins</CardTitle>
            <CardDescription>Loading...</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-center text-muted-foreground">
              Checking if running in World App...
            </p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="container mx-auto p-4 space-y-6">
      {/* Header */}
      <Card className="max-w-4xl mx-auto">
        <CardHeader>
          <CardTitle>WorldCoins Factory</CardTitle>
          <CardDescription>
            Create your own tokens and claim from others. Fixed supply: 1,000,000 tokens.
            Creator gets 5,000, each user can claim 50.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* World App Notice */}
          {isWorldApp === false && (
            <div className="p-3 bg-yellow-100 border border-yellow-400 text-yellow-700 rounded">
              <p className="font-semibold">⚠️ Limited Access</p>
              <p className="text-sm">You can browse tokens below, but you need to open this app in World App to create tokens or claim tokens.</p>
            </div>
          )}

          {/* Error Display */}
          {error && (
            <div className="p-3 bg-red-100 border border-red-400 text-red-700 rounded">
              {error}
            </div>
          )}

          {/* Interactive Features - Only show when in World App */}
          {isWorldApp && (
            <>
              {/* Wallet Connection */}
              <div>
                <Button
                  onClick={handleWalletAuth}
                  disabled={isLoading || !!userAddress}
                  className="w-full"
                >
                  {userAddress ? 
                    `Connected: ${username || `${userAddress.slice(0, 6)}...${userAddress.slice(-4)}`}` : 
                    'Connect Wallet'
                  }
                </Button>
              </div>

              {/* World ID Verification */}
              {userAddress && (
                <div>
                  <Button
                    onClick={handleVerifyWorldID}
                    disabled={isLoading || isVerified}
                    className="w-full"
                    variant={isVerified ? 'default' : 'outline'}
                  >
                    {isVerified ? '✅ World ID Verified' : 'Verify World ID'}
                  </Button>
                </div>
              )}

              {/* Token Creation */}
              {isVerified && userAddress && (
                <div className="space-y-4">
                  {!hasCreatedToken && !showCreateForm && (
                    <Button
                      onClick={() => setShowCreateForm(true)}
                      className="w-full"
                      variant="outline"
                    >
                      Create Your Token
                    </Button>
                  )}

                  {showCreateForm && (
                    <div className="space-y-3 p-4 border rounded">
                      <h3 className="font-semibold">Create Your Token</h3>
                      <input
                        type="text"
                        placeholder="Token Name (e.g., MyToken)"
                        value={tokenForm.name}
                        onChange={(e) => setTokenForm(prev => ({ ...prev, name: e.target.value }))}
                        className="w-full p-2 border rounded"
                      />
                      <input
                        type="text"
                        placeholder="Token Symbol (e.g., MTK)"
                        value={tokenForm.symbol}
                        onChange={(e) => setTokenForm(prev => ({ ...prev, symbol: e.target.value.toUpperCase() }))}
                        className="w-full p-2 border rounded"
                      />
                      <textarea
                        placeholder="Description (optional)"
                        value={tokenForm.description}
                        onChange={(e) => setTokenForm(prev => ({ ...prev, description: e.target.value }))}
                        className="w-full p-2 border rounded h-20"
                      />
                      <div className="flex gap-2">
                        <Button
                          onClick={handleCreateToken}
                          disabled={isLoading || !tokenForm.name || !tokenForm.symbol}
                          className="flex-1"
                        >
                          Create Token
                        </Button>
                        <Button
                          onClick={() => setShowCreateForm(false)}
                          variant="outline"
                          className="flex-1"
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  )}

                  {hasCreatedToken && (
                    <div className="p-3 bg-green-100 border border-green-400 text-green-700 rounded">
                      ✅ You have already created your token!
                    </div>
                  )}
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* All Tokens - Always visible */}
      <Card className="max-w-4xl mx-auto">
        <CardHeader>
          <CardTitle>All Tokens ({allTokens.length})</CardTitle>
          <CardDescription>
            Browse and claim tokens created by the community
            {isWorldApp === false && (
              <span className="block text-yellow-600 text-sm mt-1">
                Open in World App to interact with tokens
              </span>
            )}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loadingTokens ? (
            <p className="text-center text-muted-foreground py-8">Loading tokens...</p>
          ) : allTokens.length === 0 ? (
            <p className="text-center text-muted-foreground py-8">No tokens created yet. Be the first!</p>
          ) : (
            <div className="grid gap-4">
              {allTokens.map((token) => (
                <div key={token.address} className="border rounded p-4 space-y-2">
                  <div className="flex justify-between items-start">
                    <div>
                      <h3 className="font-semibold">{token.name} ({token.symbol})</h3>
                      <p className="text-sm text-muted-foreground">{token.description}</p>
                      <p className="text-xs text-muted-foreground">
                        Creator: {token.creator.slice(0, 6)}...{token.creator.slice(-4)}
                      </p>
                    </div>
                    <div className="text-right text-sm">
                      <p>Supply: {parseInt(token.totalSupply).toLocaleString()} / {parseInt(token.maxSupply).toLocaleString()}</p>
                      <p>Claimers: {token.claimStats.claimers}</p>
                      <p>Available: {parseInt(token.claimStats.availableSupply).toLocaleString()}</p>
                    </div>
                  </div>
                  
                  {/* Only show claim button when in World App and user is verified */}
                  {isWorldApp && isVerified && userAddress && token.creator.toLowerCase() !== userAddress.toLowerCase() && (
                    <Button
                      onClick={() => handleClaimTokens(token.address)}
                      disabled={isLoading}
                      size="sm"
                      className="w-full"
                    >
                      Claim 50 {token.symbol}
                    </Button>
                  )}
                  
                  {/* Show disabled claim button when not in World App */}
                  {!isWorldApp && (
                    <Button
                      disabled
                      size="sm"
                      className="w-full"
                      variant="outline"
                    >
                      Open in World App to Claim
                    </Button>
                  )}
                  
                  {isWorldApp && token.creator.toLowerCase() === userAddress?.toLowerCase() && (
                    <div className="text-sm text-blue-600 font-medium">Your Token</div>
                  )}
                </div>
              ))}
            </div>
          )}
          
          <div className="mt-4">
            <Button
              onClick={fetchAllTokens}
              variant="outline"
              size="sm"
              disabled={loadingTokens}
            >
              {loadingTokens ? 'Refreshing...' : 'Refresh'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
