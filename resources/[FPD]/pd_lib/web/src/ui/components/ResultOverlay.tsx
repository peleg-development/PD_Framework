import { useEffect, useMemo, useRef, useState } from 'react'
import type { ResultData, ResultField, ResultKind } from '../types'

const kindTheme: Record<ResultKind, { accent: string; label: string }> = {
  idcard: { accent: '#0ea5e9', label: 'IDENTIFICATION' },
  pedcheck: { accent: '#3b82f6', label: 'DISPATCH' },
  vehiclecheck: { accent: '#14b8a6', label: 'VEHICLE' },
  search: { accent: '#f59e0b', label: 'SEARCH' },
  generic: { accent: '#a855f7', label: 'RESULT' },
}

function clampDuration(ms: unknown) {
  if (typeof ms !== 'number') return 9000
  return Math.max(1000, Math.min(45000, ms))
}

function FieldRow({ field, mono }: { field: ResultField; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-4 py-1.5">
      <div className="text-xs uppercase tracking-wide" style={{ color: 'rgba(255,255,255,0.55)' }}>
        {field.label}
      </div>
      <div
        className={`text-sm font-semibold text-right ${mono ? 'font-mono' : ''}`}
        style={{ color: field.color || 'rgba(255,255,255,0.92)' }}
      >
        {field.value}
      </div>
    </div>
  )
}

function groupSearchFields(fields: ResultField[]) {
  const observations: ResultField[] = []
  const items: ResultField[] = []
  for (const f of fields) {
    if ((f.label || '').toLowerCase() === 'observation') observations.push(f)
    else items.push(f)
  }
  return { observations, items }
}

export function ResultOverlay({
  apiRef,
}: {
  apiRef: (showFn: (origin: string, data: ResultData) => void, closeFn: () => void) => void
}) {
  const [visible, setVisible] = useState(false)
  const [data, setData] = useState<ResultData | null>(null)
  const closeTimer = useRef<number | null>(null)

  const clearTimer = () => {
    if (closeTimer.current) {
      window.clearTimeout(closeTimer.current)
      closeTimer.current = null
    }
  }

  const close = () => {
    clearTimer()
    setVisible(false)
    setData(null)
  }

  useEffect(() => {
    const showFn = (_: string, d: ResultData) => {
      clearTimer()
      setData(d)
      setVisible(true)
      const ms = clampDuration(d?.duration)
      closeTimer.current = window.setTimeout(() => {
        setVisible(false)
        setData(null)
      }, ms)
    }
    apiRef(showFn, close)
    return () => clearTimer()
  }, [apiRef])

  const kind = (data?.kind as ResultKind) || 'generic'
  const theme = kindTheme[kind]
  const fields = useMemo(() => (Array.isArray(data?.fields) ? data.fields : []), [data])

  const isId = kind === 'idcard'
  const isDispatch = kind === 'pedcheck' || kind === 'vehiclecheck'
  const isSearch = kind === 'search'
  const width = isId ? 540 : isSearch ? 420 : 380

  const searchGroups = useMemo(() => (isSearch ? groupSearchFields(fields) : { observations: [], items: [] }), [isSearch, fields])
  if (!data && !visible) return null

  const positionClass = isId ? 'top-[14%] right-[2%]' : 'left-[1.6%] bottom-[22%]'

  return (
    <div
      className={`fixed ${positionClass} z-40 transition-all duration-200 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'}`}
      style={{ fontFamily: '"Roboto Condensed", "Arial Narrow", Arial, sans-serif' }}
    >
      <div
        className="rounded-md overflow-hidden relative"
        style={{
          width,
          background: isId ? '#f8fafc' : '#1a1a1a',
          boxShadow: '0 10px 28px rgba(0,0,0,0.55)',
          border: `1px solid ${isId ? 'rgba(30, 41, 59, 0.25)' : 'rgba(255,255,255,0.08)'}`,
        }}
      >
        {!isId && (
          <div className="absolute left-0 top-0 bottom-0 w-1" style={{ background: theme.accent }} />
        )}
        {isId ? (
          <>
            <div
              className="px-4 py-3"
              style={{
                background: 'linear-gradient(90deg, rgba(14, 165, 233, 0.18) 0%, rgba(2, 132, 199, 0.10) 60%, rgba(15, 23, 42, 0.03) 100%)',
                borderBottom: '1px solid rgba(30, 41, 59, 0.15)',
              }}
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <div className="text-[11px] font-bold tracking-[0.22em] text-slate-700">{theme.label}</div>
                  <div className="text-lg font-extrabold text-slate-900 mt-0.5">{data?.title}</div>
                  {data?.subtitle && <div className="text-xs text-slate-600 mt-0.5">{data.subtitle}</div>}
                </div>
                <div className="w-2 h-12 rounded-sm" style={{ background: theme.accent }} />
              </div>
            </div>

            <div className="px-4 py-4">
              <div className="flex gap-4">
                <div
                  className="w-[120px] h-[150px] rounded-md flex items-center justify-center"
                  style={{
                    background: 'linear-gradient(180deg, rgba(148, 163, 184, 0.25) 0%, rgba(148, 163, 184, 0.12) 100%)',
                    border: '1px solid rgba(15, 23, 42, 0.12)',
                  }}
                >
                  <div className="w-12 h-12 rounded-full" style={{ background: 'rgba(15, 23, 42, 0.10)' }} />
                </div>

                <div className="flex-1">
                  <div className="grid grid-cols-2 gap-x-6">
                    {fields.map((f, i) => (
                      <div key={`${f.label}_${i}`} className="py-1.5">
                        <div className="text-[11px] uppercase tracking-wide text-slate-500">{f.label}</div>
                        <div className="text-sm font-bold text-slate-900 mt-0.5">{f.value}</div>
                      </div>
                    ))}
                  </div>

                  <div
                    className="mt-3 h-8 rounded"
                    style={{
                      background:
                        'repeating-linear-gradient(90deg, rgba(15, 23, 42, 0.65) 0px, rgba(15, 23, 42, 0.65) 3px, rgba(15, 23, 42, 0.10) 3px, rgba(15, 23, 42, 0.10) 6px)',
                    }}
                  />
                  <div className="text-[10px] text-slate-500 mt-1">Scan Code</div>
                </div>
              </div>
            </div>
          </>
        ) : (
          <>
            <div
              className="px-4 py-3"
              style={{
                paddingLeft: 20,
              }}
            >
              <div className="text-[11px] font-bold tracking-[0.22em] text-white/60">{theme.label}</div>
              <div className="text-base font-bold text-white mt-0.5">{data?.title}</div>
              {data?.subtitle && <div className="text-xs text-white/60 mt-0.5">{data.subtitle}</div>}
            </div>

            <div className="px-4 py-3" style={{ paddingLeft: 20, borderTop: '1px solid rgba(255,255,255,0.06)' }}>
              {isSearch ? (
                <div className="flex flex-col gap-2">
                  {searchGroups.observations.slice(0, 2).map((f, i) => (
                    <div key={`obs_${i}`} className="flex items-start gap-2">
                      <div className="mt-[6px] w-2 h-2 rounded-full" style={{ background: 'rgba(96,165,250,0.9)' }} />
                      <div className="text-sm text-white/85 leading-relaxed">{f.value}</div>
                    </div>
                  ))}

                  {searchGroups.items.length === 0 && searchGroups.observations.length === 0 ? (
                    <div className="text-sm text-white/70">Nothing found.</div>
                  ) : (
                    <div className="flex flex-col">
                      {searchGroups.items.slice(0, 5).map((f, i) => (
                        <FieldRow key={`${f.label}_${i}`} field={f} mono={false} />
                      ))}
                      {searchGroups.items.length > 5 && (
                        <div className="text-xs text-white/45 mt-1">+ {searchGroups.items.length - 5} more</div>
                      )}
                    </div>
                  )}
                </div>
              ) : (
                <div className="flex flex-col">
                  {fields.map((f, i) => (
                    <FieldRow key={`${f.label}_${i}`} field={f} mono={isDispatch} />
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  )
}


