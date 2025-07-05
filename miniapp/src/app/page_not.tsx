'use client'

import { useEffect, useState } from 'react'
import { MiniKit } from '@worldcoin/minikit-js'

export default function TestPage() {
  const [isInstalled, setIsInstalled] = useState<boolean | null>(null)

  useEffect(() => {
    const checkMiniKit = () => {
      const installed = MiniKit.isInstalled()
      console.log('MiniKit.isInstalled():', installed)
      setIsInstalled(installed)
    }

    checkMiniKit()
  }, [])

  return (
    <div className="container mx-auto p-8">
      <h1 className="text-2xl font-bold mb-4">WorldCoins MiniApp Test</h1>
      
      <div className="bg-gray-100 p-4 rounded-lg">
        <h2 className="text-lg font-semibold mb-2">MiniKit Status:</h2>
        <p className="text-lg">
          MiniKit.isInstalled(): {' '}
          <span className={`font-mono ${isInstalled ? 'text-green-600' : 'text-red-600'}`}>
            {isInstalled !== null ? isInstalled.toString() : 'Loading...'}
          </span>
        </p>
        
        {isInstalled !== null && (
          <p className="text-sm text-gray-600 mt-2">
            {isInstalled 
              ? '✅ Running inside World App' 
              : '❌ Not running inside World App - open this in World App to test'}
          </p>
        )}
      </div>

      <div className="mt-4 text-sm text-gray-500">
        <p>Check the browser console for the logged output.</p>
      </div>
    </div>
  )
}
