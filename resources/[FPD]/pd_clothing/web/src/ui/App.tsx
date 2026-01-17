import { useState } from 'react'
import { useNuiMessages } from './useNuiMessages'
import { ClothingMenu } from './components/ClothingMenu'
import type { NuiMessage, Appearance, PresetOutfit } from './types'

export function App() {
  const [isOpen, setIsOpen] = useState(false)
  const [appearance, setAppearance] = useState<Appearance>({})
  const [outfits, setOutfits] = useState<PresetOutfit[]>([])

  useNuiMessages((msg: NuiMessage) => {
    if (msg.type === 'open') {
      setIsOpen(true)
      if (msg.appearance) {
        setAppearance(msg.appearance)
      }
      if (msg.outfits) {
        setOutfits(msg.outfits)
      }
      return
    }

    if (msg.type === 'close') {
      setIsOpen(false)
      return
    }

    if (msg.type === 'updateData') {
      if (msg.appearance) {
        setAppearance(msg.appearance)
      }
      if (msg.outfits) {
        setOutfits(msg.outfits)
      }
      return
    }

    if (msg.type === 'appearanceSaved') {
      return
    }

    if (msg.type === 'appearanceSaveFailed') {
      alert('Failed to save appearance. Please try again.')
      return
    }
  })

  if (!isOpen) {
    return null
  }

  return (
    <div className="fixed inset-0 z-50 pointer-events-auto">
      <ClothingMenu
        appearance={appearance}
        outfits={outfits}
        onAppearanceChange={setAppearance}
      />
    </div>
  )
}

