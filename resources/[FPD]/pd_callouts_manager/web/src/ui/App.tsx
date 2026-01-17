import { useCallback, useEffect, useMemo, useState } from 'react'
import type { OfferMessage } from './types'
import { useNuiMessages } from './useNuiMessages'

type OfferState = {
  id: string
  callout: OfferMessage['callout']
  distance?: number
  expiresAt: number
}

// Dispatch alert sound using Web Audio API
function playDispatchSound() {
  try {
    const ctx = new (window.AudioContext || (window as any).webkitAudioContext)()
    
    // Two-tone alert (like police radio)
    const playTone = (freq: number, start: number, duration: number) => {
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.frequency.value = freq
      osc.type = 'sine'
      gain.gain.setValueAtTime(0.3, ctx.currentTime + start)
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + start + duration)
      osc.start(ctx.currentTime + start)
      osc.stop(ctx.currentTime + start + duration)
    }

    // Play dispatch tones (two-tone alert pattern)
    playTone(800, 0, 0.15)
    playTone(600, 0.18, 0.15)
    playTone(800, 0.4, 0.15)
    playTone(600, 0.58, 0.15)
  } catch (e) {
    console.warn('Could not play dispatch sound:', e)
  }
}

// Icons
const IconAvailable = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
  </svg>
)
const IconEnRoute = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M12 2L4.5 20.29l.71.71L12 18l6.79 3 .71-.71z"/>
  </svg>
)
const IconOnScene = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
  </svg>
)
const IconBusy = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
  </svg>
)
const IconPanic = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
    <path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/>
  </svg>
)

export function App() {
  const [offer, setOffer] = useState<OfferState | null>(null)
  const [now, setNow] = useState<number>(() => Date.now())
  const [activeTab, setActiveTab] = useState('INCIDENT')

  const onMsg = useCallback((msg: any) => {
    if (msg?.type === 'hide') {
      setOffer(null)
      return
    }
    if (msg?.type === 'offer') {
      const timeoutMs = typeof msg.timeoutMs === 'number' ? msg.timeoutMs : 15000
      setOffer({
        id: msg.id,
        callout: msg.callout,
        distance: msg.distance,
        expiresAt: Date.now() + timeoutMs,
      })
      // Play dispatch alert sound
      playDispatchSound()
    }
  }, [])

  useNuiMessages(onMsg)

  useEffect(() => {
    if (!offer) return
    const t = window.setInterval(() => setNow(Date.now()), 100)
    return () => window.clearInterval(t)
  }, [offer])

  const remainingMs = useMemo(() => {
    if (!offer) return 0
    return Math.max(0, offer.expiresAt - now)
  }, [offer, now])

  const remainingSec = Math.ceil(remainingMs / 1000)

  if (!offer) return null

  const timestamp = new Date().toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: '2-digit' }) + ' ' + new Date().toLocaleTimeString('en-US', { hour12: false })

  return (
    <div className="fixed right-4 top-1/2 -translate-y-1/2 w-[520px] select-none" style={{ fontFamily: 'Segoe UI, Tahoma, sans-serif' }}>
      <div className="bg-[#1a1e2e] border border-[#2a3045] text-[#c8d0e0] text-sm shadow-2xl">
        
        {/* Title Bar */}
        <div className="bg-[#252a3d] px-3 py-1.5 flex items-center justify-between border-b border-[#2a3045]">
          <span className="text-[#9ca8c0]">Callout Interface: <span className="text-[#e0e4ed]">UNIT-{offer.id.slice(0,4).toUpperCase()}</span></span>
          <span className="text-[#9ca8c0]">Status: <span className="text-[#f0c040]">Pending ({remainingSec}s)</span></span>
        </div>

        {/* Toolbar */}
        <div className="bg-[#1f2436] px-2 py-1.5 flex items-center gap-1 border-b border-[#2a3045]">
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#2a3148] rounded text-[#8090a8] hover:text-[#a0b0c8] min-w-[52px]">
            <IconAvailable />
            <span className="text-[10px] mt-0.5">Available</span>
          </button>
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#2a3148] rounded text-[#8090a8] hover:text-[#a0b0c8] min-w-[52px]">
            <IconEnRoute />
            <span className="text-[10px] mt-0.5">En Route</span>
          </button>
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#2a3148] rounded text-[#8090a8] hover:text-[#a0b0c8] min-w-[52px]">
            <IconOnScene />
            <span className="text-[10px] mt-0.5">On Scene</span>
          </button>
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#2a3148] rounded text-[#8090a8] hover:text-[#a0b0c8] min-w-[52px]">
            <IconBusy />
            <span className="text-[10px] mt-0.5">Busy</span>
          </button>
          <div className="w-px h-8 bg-[#2a3045] mx-1" />
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#2a3148] rounded text-[#8090a8] hover:text-[#a0b0c8] min-w-[52px]">
            <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
              <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
            </svg>
            <span className="text-[10px] mt-0.5">ID Check</span>
          </button>
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#2a3148] rounded text-[#8090a8] hover:text-[#a0b0c8] min-w-[52px]">
            <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5">
              <path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 14H4V6h16v12zM6 10h2v2H6zm0 4h8v2H6zm10 0h2v2h-2zm-6-4h8v2h-8z"/>
            </svg>
            <span className="text-[10px] mt-0.5">Plate</span>
          </button>
          <div className="flex-1" />
          <button className="flex flex-col items-center px-2 py-1 hover:bg-[#4a2020] rounded text-[#d05050] min-w-[52px]">
            <IconPanic />
            <span className="text-[10px] mt-0.5">Panic</span>
          </button>
        </div>

        {/* Info Section */}
        <div className="p-3">
          {/* Top row */}
          <div className="grid grid-cols-[1fr_auto] gap-4 mb-3">
            <div>
              <div className="text-[10px] text-[#6a7a90] uppercase tracking-wide">Address</div>
              <div className="text-base text-[#e0e4ed]">{offer.callout.title}</div>
            </div>
            <div className="text-right">
              <div className="text-[10px] text-[#6a7a90] uppercase tracking-wide">Agency</div>
              <div className="text-[#e0e4ed]">{offer.callout.department || 'LSPD'}</div>
            </div>
          </div>

          {/* Middle row */}
          <div className="grid grid-cols-3 gap-4 mb-3">
            <div>
              <div className="text-[10px] text-[#6a7a90] uppercase tracking-wide">Area</div>
              <div className="text-[#e0e4ed]">LOS SANTOS</div>
            </div>
            <div>
              <div className="text-[10px] text-[#6a7a90] uppercase tracking-wide">County</div>
              <div className="text-[#e0e4ed]">LOS SANTOS</div>
            </div>
            <div>
              <div className="text-[10px] text-[#6a7a90] uppercase tracking-wide">Priority</div>
              <div className="text-[#f0c040]">{offer.callout.code}</div>
            </div>
          </div>

          {/* Details */}
          <div>
            <div className="text-[10px] text-[#6a7a90] uppercase tracking-wide mb-1">Details</div>
            <div className="bg-[#151825] border border-[#252a3d] p-2 text-[#b0b8c8] text-xs leading-relaxed min-h-[80px] max-h-[120px] overflow-y-auto font-mono">
              ------ INCIDENT OPENED at {timestamp} ------<br/>
              {offer.callout.description}<br/>
              <br/>
              *** Press [Y] to respond ***
            </div>
          </div>
        </div>

        {/* Bottom Tabs */}
        <div className="flex border-t border-[#2a3045]">
          {['INCIDENT', 'CALLOUTS', 'PEDS', 'VEHICLES', 'ALPR'].map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 text-xs font-medium transition-colors ${
                activeTab === tab 
                  ? 'bg-[#2a3148] text-[#e0e4ed]' 
                  : 'bg-[#1a1e2e] text-[#6a7a90] hover:bg-[#222738] hover:text-[#8a9ab0]'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Timer bar */}
        <div className="h-1 bg-[#151825]">
          <div 
            className="h-full bg-[#f0c040] transition-all duration-100" 
            style={{ width: `${(remainingMs / 15000) * 100}%` }} 
          />
        </div>
      </div>
    </div>
  )
}


