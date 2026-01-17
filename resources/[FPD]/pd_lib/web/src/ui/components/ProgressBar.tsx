import { useEffect, useMemo, useState } from 'react'
import type { ProgressData } from '../types'
import { postNui } from '../nui'

type ProgressState = {
  origin: string
  id: string
  data: ProgressData
  startedAt: number
}

function playComplete() {
  try {
    const ctx = new AudioContext()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.frequency.value = 800
    osc.type = 'sine'
    gain.gain.setValueAtTime(0.1, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1)
    osc.start()
    osc.stop(ctx.currentTime + 0.1)
  } catch {}
}

function playCancel() {
  try {
    const ctx = new AudioContext()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.frequency.value = 300
    osc.type = 'sine'
    gain.gain.setValueAtTime(0.1, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15)
    osc.start()
    osc.stop(ctx.currentTime + 0.15)
  } catch {}
}

export function ProgressBar({ startRef }: { startRef: (fn: (origin: string, id: string, data: ProgressData) => void) => void }) {
  const [state, setState] = useState<ProgressState | null>(null)
  const [now, setNow] = useState<number>(() => Date.now())

  useEffect(() => {
    startRef((origin, id, data) => {
      setState({
        origin,
        id,
        data,
        startedAt: Date.now(),
      })
    })
  }, [startRef])

  useEffect(() => {
    if (!state) return
    const t = window.setInterval(() => setNow(Date.now()), 50)
    return () => window.clearInterval(t)
  }, [state])

  useEffect(() => {
    if (!state) return
    const duration = Math.max(0, state.data.duration)
    const timer = window.setTimeout(() => {
      playComplete()
      postNui('pd_lib_progress_result', { origin: state.origin, id: state.id, success: true })
      setState(null)
    }, duration)
    return () => window.clearTimeout(timer)
  }, [state])

  useEffect(() => {
    if (!state || !state.data.canCancel) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        playCancel()
        postNui('pd_lib_progress_result', { origin: state.origin, id: state.id, success: false })
        setState(null)
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [state])

  const pct = useMemo(() => {
    if (!state) return 0
    const elapsed = now - state.startedAt
    const duration = Math.max(1, state.data.duration)
    return Math.max(0, Math.min(100, (elapsed / duration) * 100))
  }, [state, now])

  // Calculate circle progress
  const radius = 38
  const circumference = 2 * Math.PI * radius
  const offset = circumference - (pct / 100) * circumference

  if (!state) return null

  return (
    <div 
      className="fixed bottom-12 left-1/2 z-40 -translate-x-1/2"
      style={{ fontFamily: 'system-ui, -apple-system, sans-serif' }}
    >
      <div 
        className="flex items-center gap-3 rounded-full pl-2 pr-4 py-2 border shadow-xl"
        style={{
          background: 'rgba(20, 20, 20, 0.4)',
          borderColor: 'rgba(255, 255, 255, 0.1)'
        }}
      >
        {/* Circular progress */}
        <div className="relative flex items-center justify-center" style={{ width: '80px', height: '80px' }}>
          {/* Background circle */}
          <svg className="transform -rotate-90" width="80" height="80">
            <circle
              cx="40"
              cy="40"
              r={radius}
              stroke="rgba(255, 255, 255, 0.08)"
              strokeWidth="6"
              fill="none"
            />
            {/* Progress circle */}
            <circle
              cx="40"
              cy="40"
              r={radius}
              stroke="url(#progress-gradient)"
              strokeWidth="6"
              fill="none"
              strokeDasharray={circumference}
              strokeDashoffset={offset}
              strokeLinecap="round"
              style={{
                transition: 'stroke-dashoffset 0.1s linear',
                filter: 'drop-shadow(0 0 6px rgba(59, 130, 246, 0.5))'
              }}
            />
            <defs>
              <linearGradient id="progress-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#3b82f6" />
                <stop offset="50%" stopColor="#60a5fa" />
                <stop offset="100%" stopColor="#93c5fd" />
              </linearGradient>
            </defs>
          </svg>
          
          {/* Center percentage */}
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-white text-xl font-bold tabular-nums" style={{ textShadow: '0 2px 8px rgba(0,0,0,0.5)' }}>
              {Math.round(pct)}
            </span>
          </div>
          
          {/* Spinning ring accent */}
          <svg className="absolute inset-0 animate-spin" style={{ animationDuration: '3s' }} width="80" height="80">
            <circle
              cx="40"
              cy="40"
              r={radius + 3}
              stroke="rgba(59, 130, 246, 0.15)"
              strokeWidth="1"
              fill="none"
              strokeDasharray="3 6"
            />
          </svg>
        </div>

        {/* Text content */}
        <div className="flex flex-col gap-0.5 min-w-[150px]">
          <span className="text-white text-[13px] font-semibold">
            {state.data.label}
          </span>
          {state.data.canCancel && (
            <span className="text-white/40 text-[10px]">
              Press ESC to cancel
            </span>
          )}
        </div>
      </div>
    </div>
  )
}