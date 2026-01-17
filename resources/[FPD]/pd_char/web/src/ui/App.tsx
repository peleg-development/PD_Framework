import { useState } from 'react'
import { useNuiMessages } from './useNuiMessages'
import { CharacterCreation } from './components/CharacterCreation'
import { SpawnSelector } from './components/SpawnSelector'
import type { NuiMessage, SpawnLocation } from './types'

export function App() {
  const [showCreation, setShowCreation] = useState(false)
  const [showSpawnSelector, setShowSpawnSelector] = useState(false)
  const [spawnLocations, setSpawnLocations] = useState<SpawnLocation[]>([])

  useNuiMessages((msg: NuiMessage) => {
    if (msg.type === 'openCreation') {
      setShowCreation(true)
      setShowSpawnSelector(false)
      return
    }

    if (msg.type === 'close') {
      setShowCreation(false)
      setShowSpawnSelector(false)
      return
    }

    if (msg.type === 'openSpawnSelector') {
      setShowSpawnSelector(true)
      setShowCreation(false)
      if (msg.spawnLocations) {
        setSpawnLocations(msg.spawnLocations)
      }
      return
    }

    if (msg.type === 'receiveSpawnLocations') {
      if (msg.spawnLocations) {
        setSpawnLocations(msg.spawnLocations)
      }
      return
    }

    if (msg.type === 'characterCreated') {
      setShowCreation(false)
      return
    }

    if (msg.type === 'characterCreateFailed') {
      alert('Failed to create character. Please try again.')
      return
    }

    if (msg.type === 'characterSelectFailed') {
      alert('Failed to select character. Please try again.')
      return
    }
  })

  const handleSpawnSelect = () => {
    setShowCreation(false)
    setShowSpawnSelector(false)
  }

  if (!showCreation && !showSpawnSelector) {
    return null
  }

  return (
    <div className="fixed inset-0 z-50 pointer-events-none">
      {showSpawnSelector ? (
        <SpawnSelector spawnLocations={spawnLocations} onSelect={handleSpawnSelect} />
      ) : showCreation ? (
        <CharacterCreation slot={1} maxSlots={1} onCancel={() => {}} onCreated={() => {}} />
      ) : null}
    </div>
  )
}
