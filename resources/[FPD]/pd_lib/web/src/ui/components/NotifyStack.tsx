import { useEffect, useMemo, useState } from 'react'
import type { NotifyData, NotifyType } from '../types'

type NotifyItem = {
  id: string
  createdAt: number
  data: NotifyData
  exiting?: boolean
}

type NotifyPosition = 'top-right' | 'bottom-left'

const typeColors: Record<NotifyType, { bg: string; text: string }> = {
  success: { bg: '#10b981', text: '#ffffff' },
  warning: { bg: '#f59e0b', text: '#ffffff' },
  error: { bg: '#ef4444', text: '#ffffff' },
  info: { bg: '#3b82f6', text: '#ffffff' },
}

function normalizePosition(pos: unknown): NotifyPosition {
  if (pos === 'bottom-left') return 'bottom-left'
  return 'top-right'
}

function playNotifySound(type: NotifyType) {
  try {
    const ctx = new AudioContext()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.frequency.value = type === 'error' ? 300 : type === 'warning' ? 500 : type === 'success' ? 700 : 600
    osc.type = 'sine'
    gain.gain.setValueAtTime(0.08, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1)
    osc.start()
    osc.stop(ctx.currentTime + 0.1)
  } catch {}
}

export function NotifyStack({ pushRef }: { pushRef: (fn: (data: NotifyData) => void) => void }) {
  const [items, setItems] = useState<NotifyItem[]>([])

  useEffect(() => {
    pushRef((data) => {
      const id = `${Date.now()}_${Math.floor(Math.random() * 100000)}`
      const duration = typeof data.duration === 'number' ? data.duration : 4000
      const pos = normalizePosition((data as any)?.position)
      const entry: NotifyItem = { id, createdAt: Date.now(), data: { ...data, position: pos } }
      setItems((prev) => [entry, ...prev].slice(0, 5))
      playNotifySound((data.type ?? 'info') as NotifyType)
      
      window.setTimeout(() => {
        setItems((prev) => prev.map((x) => x.id === id ? { ...x, exiting: true } : x))
      }, duration - 300)
      
      window.setTimeout(() => {
        setItems((prev) => prev.filter((x) => x.id !== id))
      }, duration)
    })
  }, [pushRef])

  const byPosition = useMemo(() => {
    const topRight: NotifyItem[] = []
    const bottomLeft: NotifyItem[] = []
    for (const it of items) {
      const pos = normalizePosition((it.data as any)?.position)
      if (pos === 'bottom-left') bottomLeft.push(it)
      else topRight.push(it)
    }
    return { topRight, bottomLeft }
  }, [items])

  return (
    <>
      {byPosition.topRight.length > 0 && (
        <div 
          className="fixed right-5 top-5 z-50 flex w-[380px] flex-col gap-2"
          style={{ fontFamily: '"Roboto Condensed", "Arial Narrow", Arial, sans-serif' }}
        >
          {byPosition.topRight.map((item) => (
            <NotifyCard key={item.id} item={item} />
          ))}
        </div>
      )}

      {byPosition.bottomLeft.length > 0 && (
        <div 
          className="fixed left-[1.6%] bottom-[22%] z-50 flex w-[420px] flex-col gap-2"
          style={{ fontFamily: '"Roboto Condensed", "Arial Narrow", Arial, sans-serif' }}
        >
          {byPosition.bottomLeft.map((item) => (
            <NotifyCard key={item.id} item={item} />
          ))}
        </div>
      )}
    </>
  )
}

function NotifyCard({ item }: { item: NotifyItem }) {
  const t = (item.data.type ?? 'info') as NotifyType
  const colors = typeColors[t]

  return (
    <div
      className={`relative transition-all duration-300 ${item.exiting ? 'opacity-0 translate-x-4' : 'opacity-100 translate-x-0'}`}
      style={{
        background: '#1a1a1a',
        boxShadow: '0 4px 12px rgba(0,0,0,0.5)'
      }}
    >
      <div 
        className="absolute left-0 top-0 bottom-0 w-1"
        style={{ background: colors.bg }}
      />

      <div className="pl-4 pr-4 py-3.5 flex items-start gap-3">
        <div 
          className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5"
          style={{ background: colors.bg }}
        >
          {t === 'success' && <span className="text-white text-sm font-bold">✓</span>}
          {t === 'warning' && <span className="text-white text-sm font-bold">!</span>}
          {t === 'error' && <span className="text-white text-sm font-bold">✕</span>}
          {t === 'info' && <span className="text-white text-sm font-bold">i</span>}
        </div>

        <div className="flex-1 min-w-0">
          {item.data.title && (
            <div className="text-sm font-semibold text-white uppercase tracking-wide">{item.data.title}</div>
          )}
          {item.data.description && (
            <div className={`text-sm text-white/80 leading-relaxed whitespace-pre-line ${item.data.title ? 'mt-1' : ''}`}>
              {item.data.description}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}


