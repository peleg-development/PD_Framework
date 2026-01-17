import { useState, useRef, useEffect } from 'react'

interface DraggableWindowProps {
  children: React.ReactNode
  className?: string
}

export function DraggableWindow({ children, className = '' }: DraggableWindowProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const [isDragging, setIsDragging] = useState(false)
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 })
  const windowRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isDragging) return
      setPosition({
        x: e.clientX - dragOffset.x,
        y: e.clientY - dragOffset.y,
      })
    }

    const handleMouseUp = () => {
      setIsDragging(false)
    }

    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove)
      document.addEventListener('mouseup', handleMouseUp)
      return () => {
        document.removeEventListener('mousemove', handleMouseMove)
        document.removeEventListener('mouseup', handleMouseUp)
      }
    }
  }, [isDragging, dragOffset])

  useEffect(() => {
    const handleHeaderMouseDown = (e: MouseEvent) => {
      const target = e.target as HTMLElement
      const header = target.closest('[data-drag-header]')
      if (header && windowRef.current) {
        const rect = windowRef.current.getBoundingClientRect()
        setDragOffset({
          x: e.clientX - rect.left,
          y: e.clientY - rect.top,
        })
        setIsDragging(true)
      }
    }

    if (windowRef.current) {
      windowRef.current.addEventListener('mousedown', handleHeaderMouseDown)
      return () => {
        if (windowRef.current) {
          windowRef.current.removeEventListener('mousedown', handleHeaderMouseDown)
        }
      }
    }
  }, [])

  return (
    <div
      ref={windowRef}
      className={`relative ${className}`}
      style={{
        transform: `translate(${position.x}px, ${position.y}px)`,
      }}
    >
      {children}
    </div>
  )
}

