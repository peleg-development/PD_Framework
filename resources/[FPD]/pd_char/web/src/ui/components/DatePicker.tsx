import { useState, useRef, useEffect } from 'react'
import { createPortal } from 'react-dom'

interface DatePickerProps {
  value: string
  onChange: (value: string) => void
  disabled?: boolean
}

export function DatePicker({ value, onChange, disabled }: DatePickerProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [selectedDate, setSelectedDate] = useState<Date | null>(
    value ? new Date(value) : null
  )
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const containerRef = useRef<HTMLDivElement>(null)
  const calendarRef = useRef<HTMLDivElement>(null)
  const [calendarPosition, setCalendarPosition] = useState({ top: 0, left: 0 })

  useEffect(() => {
    if (value) {
      const date = new Date(value)
      if (!isNaN(date.getTime())) {
        setSelectedDate(date)
        setCurrentMonth(new Date(date.getFullYear(), date.getMonth(), 1))
      }
    }
  }, [value])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node
      if (
        containerRef.current && 
        !containerRef.current.contains(target) &&
        calendarRef.current &&
        !calendarRef.current.contains(target)
      ) {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect()
        setCalendarPosition({
          top: rect.bottom + 8,
          left: rect.left
        })
      }
      document.addEventListener('mousedown', handleClickOutside)
      return () => document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [isOpen])

  const formatDate = (date: Date | null): string => {
    if (!date) return ''
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    const year = date.getFullYear()
    return `${month}/${day}/${year}`
  }

  const handleDateSelect = (day: number) => {
    const newDate = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day)
    setSelectedDate(newDate)
    onChange(formatDate(newDate))
    setIsOpen(false)
  }

  const getDaysInMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
  }

  const getFirstDayOfMonth = (date: Date) => {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay()
  }

  const navigateMonth = (direction: number) => {
    setCurrentMonth(
      new Date(currentMonth.getFullYear(), currentMonth.getMonth() + direction, 1)
    )
  }

  const renderCalendar = () => {
    const daysInMonth = getDaysInMonth(currentMonth)
    const firstDay = getFirstDayOfMonth(currentMonth)
    const days: (number | null)[] = []

    for (let i = 0; i < firstDay; i++) {
      days.push(null)
    }

    for (let i = 1; i <= daysInMonth; i++) {
      days.push(i)
    }

    const isSelected = (day: number) => {
      if (!selectedDate) return false
      return (
        selectedDate.getDate() === day &&
        selectedDate.getMonth() === currentMonth.getMonth() &&
        selectedDate.getFullYear() === currentMonth.getFullYear()
      )
    }

    return (
      <div className="grid grid-cols-7 gap-1">
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
          <div key={day} className="text-xs text-[#9ca3af] text-center py-2 font-medium">
            {day}
          </div>
        ))}
        {days.map((day, idx) =>
          day ? (
            <button
              key={idx}
              onClick={() => handleDateSelect(day)}
              className={`p-2 text-sm rounded-lg transition-colors ${
                isSelected(day)
                  ? 'bg-[#5a6f9a] text-white font-semibold'
                  : 'text-[#d1d5db] hover:bg-[#252836]'
              }`}
            >
              {day}
            </button>
          ) : (
            <div key={idx}></div>
          )
        )}
      </div>
    )
  }

  const calendarElement = isOpen && !disabled ? (
    <div 
      ref={calendarRef} 
      className="fixed bg-[#1a1d29] border-2 border-[#2d3142] rounded-xl shadow-xl p-4 min-w-[280px] pointer-events-auto" 
      style={{ top: `${calendarPosition.top}px`, left: `${calendarPosition.left}px`, zIndex: 99999 }}
    >
      <div className="flex items-center justify-between mb-4">
        <button
          onClick={() => navigateMonth(-1)}
          className="p-1.5 text-[#9ca3af] hover:text-white hover:bg-[#252836] rounded transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <div className="text-white font-semibold">
          {currentMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
        </div>
        <button
          onClick={() => navigateMonth(1)}
          className="p-1.5 text-[#9ca3af] hover:text-white hover:bg-[#252836] rounded transition-colors"
        >
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>
      {renderCalendar()}
    </div>
  ) : null

  return (
    <>
      <div ref={containerRef} className="relative">
        <input
          type="text"
          value={formatDate(selectedDate)}
          readOnly
          onClick={() => !disabled && setIsOpen(!isOpen)}
          className="w-full px-4 py-3 bg-[#252836] text-white rounded-lg border border-[#3d4254] focus:border-[#5a6f9a] focus:outline-none focus:ring-2 focus:ring-[#5a6f9a] transition-all cursor-pointer placeholder:text-[#6b7280]"
          placeholder="MM/DD/YYYY"
          disabled={disabled}
        />
      </div>
      {calendarElement && createPortal(calendarElement, document.body)}
    </>
  )
}

