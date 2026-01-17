import { postNui } from '../nui'
import type { PresetOutfit, Appearance } from '../types'

interface PresetSelectorProps {
  outfits: PresetOutfit[]
  onSelect: (outfit: PresetOutfit) => void
}

export function PresetSelector({ outfits, onSelect }: PresetSelectorProps) {
  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const handleSelect = (outfit: PresetOutfit) => {
    playClickSound()
    onSelect(outfit)
  }

  if (outfits.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-[#9ca3af] text-lg">No preset outfits available</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {outfits.map((outfit) => (
        <button
          key={outfit.name}
          type="button"
          onClick={() => handleSelect(outfit)}
          className="bg-[#252836] hover:bg-[#2d3142] border-2 border-[#3d4254] hover:border-[#4a5f8f] rounded-lg p-6 transition-all text-left"
        >
          <div className="mb-3">
            <h3 className="text-xl font-semibold text-white mb-1">{outfit.label}</h3>
            <p className="text-sm text-[#9ca3af]">{outfit.name}</p>
          </div>
          <div className="text-[#5a6f9a] text-sm font-medium">Click to apply</div>
        </button>
      ))}
    </div>
  )
}

