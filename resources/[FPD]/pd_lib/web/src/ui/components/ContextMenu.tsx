import { useEffect, useMemo, useRef, useState, useCallback } from 'react'
import { ChevronLeft, ChevronRight, ChevronUp, ChevronDown, CornerDownLeft, X } from 'lucide-react'

// Types
export interface ContextOption {
  id: string
  title: string
  description?: string
  value?: string
  values?: string[]
  valueIndex?: number
  disabled?: boolean
  color?: string
  valueColor?: string
}

export interface ContextData {
  id: string
  title: string
  description?: string
  options?: ContextOption[]
}

// NUI Communication
export const postNui = (event: string, data: unknown) => {
  // @ts-expect-error - FiveM NUI callback
  if (typeof fetch === 'function' && window.GetParentResourceName) {
    // @ts-expect-error - FiveM NUI callback
    fetch(`https://${window.GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
  }
}

// Audio
let audioCtx: AudioContext | null = null
function getAudioContext() {
  if (!audioCtx || audioCtx.state === 'closed') {
    audioCtx = new AudioContext()
  }
  return audioCtx
}

function playSound(freq: number, duration: number, volume: number = 0.08) {
  try {
    const ctx = getAudioContext()
    if (ctx.state === 'suspended') ctx.resume()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.frequency.value = freq
    osc.type = 'sine'
    gain.gain.setValueAtTime(volume, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration)
    osc.start(ctx.currentTime)
    osc.stop(ctx.currentTime + duration)
  } catch {}
}

function playClick() { playSound(1000, 0.03, 0.06) }
function playSelect() { playSound(800, 0.08, 0.1) }
function playChange() { playSound(600, 0.03, 0.05) }

// Component
interface ContextMenuProps {
  openRef: (fn: (origin: string, ctx: ContextData) => void, close: () => void) => void
}

export function ContextMenu({ openRef }: ContextMenuProps) {
  const [ctx, setCtx] = useState<ContextData | null>(null)
  const [origin, setOrigin] = useState<string>('')
  const [selected, setSelected] = useState<number>(0)
  const [valueIndices, setValueIndices] = useState<Record<string, number>>({})
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null)
  const scrollRef = useRef<HTMLDivElement>(null)

  const closeInternal = useCallback(() => {
    setCtx(null)
    setOrigin('')
    setSelected(0)
    setValueIndices({})
  }, [])

  const close = useCallback(() => {
    closeInternal()
    postNui('pd_lib_context_close', {})
  }, [closeInternal])

  const open = useCallback((o: string, c: ContextData) => {
    const indices: Record<string, number> = {}
    c.options?.forEach(opt => {
      if (opt.values && opt.values.length > 0) {
        indices[opt.id] = opt.valueIndex ?? 0
      }
    })
    setOrigin(o)
    setSelected(0)
    setValueIndices(indices)
    setCtx(c)
  }, [])

  useEffect(() => {
    openRef(open, closeInternal)
  }, [openRef, open, closeInternal])

  useEffect(() => {
    if (!scrollRef.current) return
    const items = scrollRef.current.children
    if (items[selected]) {
      (items[selected] as HTMLElement).scrollIntoView({ block: 'nearest', behavior: 'smooth' })
    }
  }, [selected])

  useEffect(() => {
    if (!ctx) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        close()
      }
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        playClick()
        setSelected((v) => Math.min((ctx.options?.length ?? 1) - 1, v + 1))
      }
      if (e.key === 'ArrowUp') {
        e.preventDefault()
        playClick()
        setSelected((v) => Math.max(0, v - 1))
      }
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        e.preventDefault()
        const opt = ctx.options?.[selected]
        if (!opt || !opt.values || opt.values.length === 0) return
        playChange()
        setValueIndices(prev => {
          const current = prev[opt.id] ?? 0
          const max = opt.values!.length - 1
          let next = e.key === 'ArrowRight' ? current + 1 : current - 1
          if (next < 0) next = max
          if (next > max) next = 0
          return { ...prev, [opt.id]: next }
        })
        const newIdx = e.key === 'ArrowRight' 
          ? Math.min((valueIndices[opt.id] ?? 0) + 1, opt.values.length - 1)
          : Math.max((valueIndices[opt.id] ?? 0) - 1, 0)
        postNui('pd_lib_context_value_change', { 
          origin, 
          contextId: ctx.id, 
          optionId: opt.id, 
          valueIndex: newIdx,
          value: opt.values[newIdx]
        })
      }
      if (e.key === 'Enter') {
        e.preventDefault()
        const opt = ctx.options?.[selected]
        if (!opt || opt.disabled) return
        playSelect()
        const currentCtx = ctx
        const currentOrigin = origin
        setCtx(null)
        setOrigin('')
        setSelected(0)
        setValueIndices({})
        postNui('pd_lib_context_select', { 
          origin: currentOrigin, 
          contextId: currentCtx.id, 
          optionId: opt.id,
          valueIndex: valueIndices[opt.id],
          value: opt.values?.[valueIndices[opt.id] ?? 0]
        })
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [ctx, origin, selected, valueIndices, close])

  const visible = useMemo(() => !!ctx, [ctx])
  if (!visible || !ctx) return null

  const optionCount = ctx.options?.length ?? 0
  const selectedOpt = ctx.options?.[selected]
  const hasInlineSelect = selectedOpt?.values && selectedOpt.values.length > 0

  return (
    <div className="fixed top-[3%] left-[2%] z-50 w-[480px] font-sans">
      {/* Header */}
      <div 
        className="relative overflow-hidden rounded-t-xl"
        style={{ background: 'linear-gradient(135deg, hsl(217 91% 50%) 0%, hsl(217 91% 40%) 100%)' }}
      >
        <div className="absolute inset-0 opacity-20">
          <div className="absolute top-0 right-0 w-32 h-32 bg-white/20 rounded-full blur-2xl -translate-y-1/2 translate-x-1/2" />
          <div className="absolute bottom-0 left-0 w-24 h-24 bg-white/10 rounded-full blur-xl translate-y-1/2 -translate-x-1/2" />
        </div>
        <div className="relative px-6 py-5">
          <div className="flex items-start justify-between">
            <div>
              <h1 className="text-xl font-bold text-white tracking-tight">{ctx.title}</h1>
              {ctx.description && (
                <p className="text-sm text-white/70 mt-1 max-w-[320px]">{ctx.description}</p>
              )}
            </div>
            <div className="flex items-center gap-2 bg-white/10 backdrop-blur-sm rounded-lg px-3 py-1.5">
              <span className="text-sm font-semibold text-white">{selected + 1}</span>
              <span className="text-white/40">/</span>
              <span className="text-sm text-white/60">{optionCount}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Menu Items */}
      <div 
        ref={scrollRef}
        className="max-h-[400px] overflow-y-auto"
        style={{ background: 'linear-gradient(180deg, hsl(220 20% 10%) 0%, hsl(220 20% 8%) 100%)', boxShadow: 'inset 0 1px 0 hsl(220 20% 15%)' }}
      >
        {(ctx.options ?? []).map((opt, idx) => {
          const isSel = idx === selected
          const disabled = !!opt.disabled
          const hasValues = opt.values && opt.values.length > 0
          const currentValueIdx = valueIndices[opt.id] ?? 0
          const displayValue = hasValues ? opt.values![currentValueIdx] : opt.value
          const isHovered = hoveredIndex === idx && !isSel && !disabled
          
          return (
            <div
              key={opt.id}
              onClick={() => { if (!disabled) { setSelected(idx); playClick() } }}
              onMouseEnter={() => !disabled && setHoveredIndex(idx)}
              onMouseLeave={() => setHoveredIndex(null)}
              className={`relative px-6 py-3.5 flex items-center gap-4 transition-all duration-200 cursor-pointer ${disabled ? 'opacity-40 cursor-not-allowed' : ''}`}
              style={{ background: isSel ? 'rgba(59, 130, 246, 0.15)' : isHovered ? 'rgba(59, 130, 246, 0.05)' : 'transparent' }}
            >
              <div 
                className="absolute left-0 top-1/2 -translate-y-1/2 w-1 rounded-r-full transition-all duration-300"
                style={{ height: isSel ? '2rem' : '0', background: isSel ? 'hsl(217 91% 60%)' : 'transparent', boxShadow: isSel ? '0 0 12px hsla(217, 91%, 60%, 0.5)' : 'none' }}
              />
              <span 
                className="flex-1 text-[15px] font-medium transition-colors duration-200"
                style={{ color: opt.color ? opt.color : isSel ? 'hsl(217 91% 70%)' : isHovered ? 'hsl(210 40% 98%)' : 'hsl(215 20% 65%)' }}
              >
                {opt.title}
              </span>
              
              {hasValues && isSel && (
                <div className="flex items-center gap-2">
                  <button 
                    className="w-6 h-6 flex items-center justify-center rounded transition-colors"
                    style={{ background: 'rgba(59, 130, 246, 0.2)', color: 'hsl(217 91% 70%)' }}
                    onClick={(e) => { e.stopPropagation(); playChange(); setValueIndices(prev => { const c = prev[opt.id] ?? 0; const m = opt.values!.length - 1; return { ...prev, [opt.id]: c <= 0 ? m : c - 1 } }) }}
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                  <span className="min-w-[90px] text-center text-sm font-semibold px-3 py-1 rounded-md" style={{ color: 'hsl(217 91% 70%)', background: 'rgba(59, 130, 246, 0.1)' }}>
                    {displayValue}
                  </span>
                  <button 
                    className="w-6 h-6 flex items-center justify-center rounded transition-colors"
                    style={{ background: 'rgba(59, 130, 246, 0.2)', color: 'hsl(217 91% 70%)' }}
                    onClick={(e) => { e.stopPropagation(); playChange(); setValueIndices(prev => { const c = prev[opt.id] ?? 0; const m = opt.values!.length - 1; return { ...prev, [opt.id]: c >= m ? 0 : c + 1 } }) }}
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              )}
              
              {displayValue && !hasValues && (
                <span className="text-sm font-semibold px-2.5 py-1 rounded-md" style={{ color: opt.valueColor || 'hsl(38 92% 50%)', background: opt.valueColor ? `${opt.valueColor}20` : 'rgba(251, 191, 36, 0.1)' }}>
                  {displayValue}
                </span>
              )}
              
              {hasValues && !isSel && (
                <span className="text-sm font-semibold px-2.5 py-1 rounded-md" style={{ color: 'hsl(38 92% 50% / 0.8)', background: 'rgba(251, 191, 36, 0.1)' }}>
                  {displayValue}
                </span>
              )}
            </div>
          )
        })}
      </div>

      {/* Footer */}
      <div className="rounded-b-xl px-5 py-3 flex items-center gap-4" style={{ background: 'hsl(220 20% 6%)', borderTop: '1px solid hsl(220 15% 15%)' }}>
        <div className="flex items-center gap-1.5" style={{ color: 'hsl(215 20% 55%)' }}>
          <div className="flex gap-0.5">
            <span className="w-5 h-5 flex items-center justify-center rounded text-[10px]" style={{ background: 'hsl(220 15% 20% / 0.5)' }}><ChevronUp className="w-3 h-3" /></span>
            <span className="w-5 h-5 flex items-center justify-center rounded text-[10px]" style={{ background: 'hsl(220 15% 20% / 0.5)' }}><ChevronDown className="w-3 h-3" /></span>
          </div>
          <span className="text-[11px]">Navigate</span>
        </div>
        {hasInlineSelect && (
          <div className="flex items-center gap-1.5" style={{ color: 'hsl(215 20% 55%)' }}>
            <div className="flex gap-0.5">
              <span className="w-5 h-5 flex items-center justify-center rounded text-[10px]" style={{ background: 'hsl(220 15% 20% / 0.5)' }}><ChevronLeft className="w-3 h-3" /></span>
              <span className="w-5 h-5 flex items-center justify-center rounded text-[10px]" style={{ background: 'hsl(220 15% 20% / 0.5)' }}><ChevronRight className="w-3 h-3" /></span>
            </div>
            <span className="text-[11px]">Adjust</span>
          </div>
        )}
        <div className="flex items-center gap-1.5" style={{ color: 'hsl(215 20% 55%)' }}>
          <span className="h-5 flex items-center justify-center rounded px-1.5 text-[10px]" style={{ background: 'hsl(220 15% 20% / 0.5)' }}><CornerDownLeft className="w-3 h-3" /></span>
          <span className="text-[11px]">Select</span>
        </div>
        <div className="flex items-center gap-1.5" style={{ color: 'hsl(215 20% 55%)' }}>
          <span className="h-5 flex items-center justify-center rounded px-1.5 text-[10px]" style={{ background: 'hsl(220 15% 20% / 0.5)' }}><X className="w-3 h-3" /></span>
          <span className="text-[11px]">Close</span>
        </div>
      </div>
    </div>
  )
}