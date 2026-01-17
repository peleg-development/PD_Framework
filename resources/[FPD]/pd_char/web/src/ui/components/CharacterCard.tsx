import type { PDCharacter } from '../types'

interface CharacterCardProps {
  character: PDCharacter
  onSelect: (slot: number) => void
  onDelete: (slot: number) => void
}

export function CharacterCard({ character, onSelect, onDelete }: CharacterCardProps) {
  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const handleSelect = () => {
    playClickSound()
    onSelect(character.slot)
  }

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation()
    playClickSound()
    if (confirm(`Are you sure you want to delete ${character.firstName} ${character.lastName}?`)) {
      onDelete(character.slot)
    }
  }

  return (
    <div className="group relative bg-[#0f1419] rounded-xl overflow-hidden border border-[#1a2332] hover:border-emerald-500 transition-all duration-300 hover:shadow-lg hover:shadow-emerald-500/30 hover:scale-[1.02]">
      <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/0 to-cyan-500/0 group-hover:from-emerald-500/10 group-hover:to-cyan-500/10 transition-all duration-300" />
      <div className="relative p-5 z-10">
        <div className="mb-4">
          <h3 className="text-xl font-bold text-white mb-1 group-hover:text-emerald-400 transition-colors">
            {character.firstName} {character.lastName}
          </h3>
          <p className="text-[#6b7a99] text-xs font-medium">Slot {character.slot}</p>
        </div>

        <div className="space-y-2 text-xs text-[#c8d0e0] mb-5">
          <div className="flex items-center gap-2">
            <span className="text-[#6b7a99] font-medium">DOB:</span>
            <span className="text-white">{character.dateOfBirth || 'Not set'}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[#6b7a99] font-medium">Gender:</span>
            <span className="text-white capitalize">{character.gender || 'Not set'}</span>
          </div>
        </div>

        <div className="flex gap-3">
          <button
            onClick={handleSelect}
            className="flex-1 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-sm font-semibold transition-all duration-200 shadow-lg shadow-emerald-500/30 hover:shadow-emerald-500/50"
          >
            Select
          </button>
          <button
            onClick={handleDelete}
            className="px-4 py-2.5 bg-[#1a2332] hover:bg-red-600 text-[#c8d0e0] hover:text-white rounded-lg text-sm font-semibold transition-all duration-200 border border-[#2a3045] hover:border-red-500"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  )
}
