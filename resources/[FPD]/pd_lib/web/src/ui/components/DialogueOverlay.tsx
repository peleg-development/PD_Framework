import { useEffect, useMemo, useRef, useState } from 'react'
import type { DialogueLine, DialogueOpenData, DialogueSide } from '../types'

type DialogueLineItem = {
  id: string
  createdAt: number
  data: DialogueLine
}

const sideTheme: Record<DialogueSide, { bubbleBg: string; text: string; name: string; align: 'left' | 'right' | 'center' }> = {
  you: { bubbleBg: '#dcf8c6', text: '#0b1220', name: 'You', align: 'right' },
  ped: { bubbleBg: '#ffffff', text: '#0b1220', name: 'Ped', align: 'left' },
  system: { bubbleBg: '#e5e7eb', text: '#111827', name: 'System', align: 'center' },
}

function fmtTime(ts: number) {
  try {
    const d = new Date(ts)
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  } catch {
    return ''
  }
}

export function DialogueOverlay({
  apiRef,
}: {
  apiRef: (
    openFn: (origin: string, data: DialogueOpenData) => void,
    pushFn: (origin: string, data: DialogueLine) => void,
    closeFn: () => void,
  ) => void
}) {
  const [visible, setVisible] = useState(false)
  const [header, setHeader] = useState<{ title?: string; subtitle?: string }>({})
  const [lines, setLines] = useState<DialogueLineItem[]>([])
  const durationRef = useRef<number>(9000)
  const closeTimer = useRef<number | null>(null)

  const clearTimer = () => {
    if (closeTimer.current) {
      window.clearTimeout(closeTimer.current)
      closeTimer.current = null
    }
  }

  const scheduleClose = () => {
    clearTimer()
    closeTimer.current = window.setTimeout(() => {
      setVisible(false)
      setLines([])
    }, durationRef.current)
  }

  useEffect(() => {
    const openFn = (_: string, data: DialogueOpenData) => {
      if (typeof data?.duration === 'number') {
        durationRef.current = Math.max(1000, Math.min(30000, data.duration))
      }
      if (data?.reset) setLines([])
      setHeader({ title: data?.title, subtitle: data?.subtitle })
      setVisible(true)
      scheduleClose()
    }

    const pushFn = (_: string, data: DialogueLine) => {
      const id = `${Date.now()}_${Math.floor(Math.random() * 100000)}`
      const line: DialogueLineItem = { id, createdAt: Date.now(), data }
      setLines((prev) => [...prev, line].slice(-7))
      setVisible(true)
      scheduleClose()
    }

    const closeFn = () => {
      clearTimer()
      setVisible(false)
      setLines([])
    }

    apiRef(openFn, pushFn, closeFn)
    return () => clearTimer()
  }, [apiRef])

  const rendered = useMemo(() => lines, [lines])
  if (!visible && rendered.length === 0) return null

  return (
    <div
      className={`fixed left-1/2 bottom-[8%] z-40 w-[520px] -translate-x-1/2 transition-all duration-200 ${
        visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'
      }`}
      style={{ fontFamily: '"Roboto Condensed", "Arial Narrow", Arial, sans-serif' }}
    >
      <div
        className="rounded-md overflow-hidden"
        style={{
          background: '#ece5dd',
          boxShadow: '0 10px 28px rgba(0,0,0,0.55)',
          border: '1px solid rgba(0,0,0,0.25)',
        }}
      >
        {(header.title || header.subtitle) && (
          <div
            className="px-4 py-3"
            style={{
              background: '#075e54',
              borderBottom: '1px solid rgba(0,0,0,0.20)',
              color: '#ffffff',
            }}
          >
            <div className="flex items-center justify-between gap-4">
              <div className="min-w-0">
                {header.title && (
                  <div className="text-sm font-bold tracking-wide truncate">{header.title}</div>
                )}
                {header.subtitle && <div className="text-xs opacity-90 truncate mt-0.5">{header.subtitle}</div>}
              </div>
              <div className="text-[11px] opacity-85 whitespace-nowrap">Online</div>
            </div>
          </div>
        )}

        <div
          className="px-4 py-3 flex flex-col gap-2"
          style={{
            background:
              'repeating-linear-gradient(45deg, rgba(0,0,0,0.03) 0px, rgba(0,0,0,0.03) 2px, rgba(255,255,255,0.00) 2px, rgba(255,255,255,0.00) 8px)',
          }}
        >
          {rendered.map((line) => {
            const side = line.data.side ?? 'system'
            const theme = sideTheme[side] ?? sideTheme.system
            const name = line.data.name || theme.name
            const time = fmtTime(line.createdAt)
            const align = theme.align
            const justify =
              align === 'right' ? 'justify-end' : align === 'left' ? 'justify-start' : 'justify-center'

            const tailSide = align === 'right' ? 'right' : align === 'left' ? 'left' : 'none'
            const tailBg = theme.bubbleBg

            return (
              <div key={line.id} className={`flex ${justify}`}>
                <div className="max-w-[92%] relative">
                  <div
                    className="px-3 py-2 rounded-[14px]"
                    style={{
                      background: theme.bubbleBg,
                      color: theme.text,
                      boxShadow: '0 2px 6px rgba(0,0,0,0.18)',
                      border: '1px solid rgba(0,0,0,0.08)',
                    }}
                  >
                    <div className="text-[11px] font-bold uppercase tracking-wide opacity-70">{name}</div>
                    <div className="text-sm leading-relaxed mt-0.5">{line.data.text}</div>
                    <div className="text-[10px] opacity-55 text-right mt-1">{time}</div>
                  </div>

                  {tailSide !== 'none' && (
                    <div
                      style={{
                        position: 'absolute',
                        bottom: 8,
                        width: 10,
                        height: 10,
                        background: tailBg,
                        transform: 'rotate(45deg)',
                        borderRadius: 2,
                        boxShadow: '0 2px 5px rgba(0,0,0,0.12)',
                        border: '1px solid rgba(0,0,0,0.06)',
                        ...(tailSide === 'right' ? { right: -4 } : { left: -4 }),
                      }}
                    />
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}


