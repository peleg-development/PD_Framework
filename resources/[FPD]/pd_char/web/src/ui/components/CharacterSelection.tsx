import { useState, useEffect } from 'react'
import type { PDCharacter } from '../types'
import { CharacterCard } from './CharacterCard'
import { CharacterCreation } from './CharacterCreation'
import { SpawnSelector } from './SpawnSelector'
import { DraggableWindow } from './DraggableWindow'
import { postNui } from '../nui'

interface CharacterSelectionProps {
  characters: PDCharacter[]
  maxCharacters: number
}

export function CharacterSelection({ characters, maxCharacters }: CharacterSelectionProps) {
  const [creatingSlot, setCreatingSlot] = useState<number | null>(null)
  const [showSpawnSelector, setShowSpawnSelector] = useState(false)
  const [selectedCharacterSlot, setSelectedCharacterSlot] = useState<number | null>(null)

  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const handleSelect = async (slot: number) => {
    playClickSound()
    setSelectedCharacterSlot(slot)
    await postNui('pd_char:selectCharacter', { slot })
  }

  const handleDelete = async (slot: number) => {
    playClickSound()
    if (confirm(`Are you sure you want to delete this character?`)) {
      await postNui('pd_char:deleteCharacter', { slot })
      postNui('pd_char:requestCharacters', {})
    }
  }

  const handleCreate = async (slot: number) => {
    playClickSound()
    setCreatingSlot(slot)
  }

  const handleCreationComplete = () => {
    setCreatingSlot(null)
  }

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data.type === 'characterCreated') {
        setCreatingSlot(null)
      }
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  const getAvailableSlots = () => {
    const usedSlots = new Set(characters.map((c) => c.slot))
    const available: number[] = []
    for (let i = 1; i <= maxCharacters; i++) {
      if (!usedSlots.has(i)) {
        available.push(i)
      }
    }
    return available
  }

  const availableSlots = getAvailableSlots()
  const displaySlots = Array.from({ length: maxCharacters }, (_, i) => i + 1)

  if (showSpawnSelector) {
    return (
      <SpawnSelector
        spawnLocations={[]}
        onSelect={() => setShowSpawnSelector(false)}
      />
    )
  }

  return (
    <div className="w-full h-full flex items-center justify-center p-4">
      <DraggableWindow className="pointer-events-auto">
        <div className="relative bg-[#0a0e1a] rounded-xl border border-[#1a2332] shadow-2xl w-[900px] max-h-[90vh] overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/5 via-transparent to-cyan-500/5 pointer-events-none" />
          <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-emerald-500/60 to-transparent" />
          
          <div data-drag-header className="sticky top-0 bg-[#0f1419] border-b border-[#1a2332] p-5 z-10 select-none">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold text-white mb-1">Character Selection</h1>
                <p className="text-[#8b9dc3] text-sm">Choose a character or create a new one</p>
              </div>
            </div>
          </div>

          <div className="p-6 relative">
            <div className="grid grid-cols-3 gap-4 mb-6">
              {displaySlots.map((slot) => {
                const character = characters.find((c) => c.slot === slot)
                if (character) {
                  return (
                    <CharacterCard
                      key={character.id}
                      character={character}
                      onSelect={handleSelect}
                      onDelete={handleDelete}
                    />
                  )
                } else {
                  return (
                    <div
                      key={slot}
                      className="group relative bg-[#0f1419] rounded-xl p-6 border-2 border-dashed border-[#1a2332] hover:border-emerald-500 transition-all duration-300 cursor-pointer flex flex-col items-center justify-center min-h-[320px] hover:shadow-lg hover:shadow-emerald-500/30"
                      onClick={() => handleCreate(slot)}
                    >
                      <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/0 to-cyan-500/0 group-hover:from-emerald-500/10 group-hover:to-cyan-500/10 rounded-xl transition-all duration-300" />
                      <div className="text-center relative z-10">
                        <div className="text-5xl text-emerald-500 mb-4 group-hover:text-emerald-400 group-hover:scale-110 transition-all duration-300">+</div>
                        <p className="text-[#c8d0e0] text-sm font-semibold mb-1 group-hover:text-white transition-colors">Create Character</p>
                        <p className="text-[#6b7a99] text-xs group-hover:text-[#8b9dc3] transition-colors">Slot {slot}</p>
                      </div>
                    </div>
                  )
                }
              })}
            </div>
          </div>
        </div>
      </DraggableWindow>

      {creatingSlot !== null && (
        <CharacterCreation
          slot={creatingSlot}
          maxSlots={maxCharacters}
          onCancel={() => setCreatingSlot(null)}
          onCreated={handleCreationComplete}
        />
      )}
    </div>
  )
}
