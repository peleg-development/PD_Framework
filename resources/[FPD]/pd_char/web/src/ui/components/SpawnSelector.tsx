import { useState, useEffect } from 'react'
import { postNui } from '../nui'

interface SpawnLocation {
  name: string
  x: number
  y: number
  z: number
  heading: number
}

interface SpawnSelectorProps {
  spawnLocations: SpawnLocation[]
  onSelect: (index: number) => void
}

export function SpawnSelector({ spawnLocations: initialLocations, onSelect }: SpawnSelectorProps) {
  const [selectedIndex, setSelectedIndex] = useState(0)
  const [spawnLocations, setSpawnLocations] = useState<SpawnLocation[]>(initialLocations)

  useEffect(() => {
    if (spawnLocations.length === 0) {
      postNui('pd_char:requestSpawnLocations', {})
    }
  }, [])

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data.type === 'receiveSpawnLocations' && event.data.spawnLocations) {
        setSpawnLocations(event.data.spawnLocations)
      }
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])

  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const handleSelect = async (index: number) => {
    playClickSound()
    setSelectedIndex(index)
    await postNui('pd_char:selectSpawn', { spawnIndex: index })
    onSelect(index)
  }

  return (
    <div className="fixed inset-0 flex items-center justify-center z-50 p-4 pointer-events-auto bg-black/40">
      <div className="w-full max-w-2xl">
        <div className="bg-[#1a1d29] rounded-2xl border-2 border-[#2d3142] shadow-2xl overflow-hidden">
          <div className="p-6 border-b border-[#2d3142]">
            <h2 className="text-2xl font-bold text-white mb-1">Select Spawn Location</h2>
            <p className="text-[#9ca3af] text-sm">Choose where you want to spawn</p>
          </div>

          <div className="p-6">
            <div className="grid grid-cols-1 gap-3">
              {spawnLocations.map((spawn, index) => (
                <button
                  key={index}
                  onClick={() => handleSelect(index)}
                  className={`group relative p-5 rounded-xl border-2 transition-all duration-200 text-left ${
                    selectedIndex === index
                      ? 'border-[#5a6f9a] bg-[#252836]'
                      : 'border-[#3d4254] bg-[#252836] hover:border-[#4a5f8f]'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-lg font-semibold text-white mb-1">{spawn.name}</h3>
                      <p className="text-[#9ca3af] text-sm">
                        {spawn.x.toFixed(1)}, {spawn.y.toFixed(1)}, {spawn.z.toFixed(1)}
                      </p>
                    </div>
                    {selectedIndex === index && (
                      <div className="w-3 h-3 bg-[#5a6f9a] rounded-full"></div>
                    )}
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

