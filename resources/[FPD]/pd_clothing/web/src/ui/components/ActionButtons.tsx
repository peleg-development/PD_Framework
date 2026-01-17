interface ActionButtonsProps {
  onSave: () => void
  onCancel: () => void
}

export function ActionButtons({ onSave, onCancel }: ActionButtonsProps) {
  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  return (
    <div className="flex gap-4">
      <button
        type="button"
        onClick={() => {
          playClickSound()
          onSave()
        }}
        className="flex-1 px-6 py-4 bg-[#4a5f8f] hover:bg-[#5a6f9a] text-white rounded-lg font-semibold text-lg transition-all duration-200"
      >
        Save Appearance
      </button>
      <button
        type="button"
        onClick={() => {
          playClickSound()
          onCancel()
        }}
        className="flex-1 px-6 py-4 bg-[#252836] hover:bg-[#2d3142] text-[#9ca3af] hover:text-white rounded-lg font-semibold text-lg transition-all duration-200 border-2 border-[#3d4254] hover:border-[#4a5f8f]"
      >
        Cancel
      </button>
    </div>
  )
}

