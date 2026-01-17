import { useState } from 'react'
import { PresetSelector } from './PresetSelector'
import { CustomizationPanel } from './CustomizationPanel'
import { ActionButtons } from './ActionButtons'
import { postNui } from '../nui'
import type { Appearance, PresetOutfit } from '../types'

interface ClothingMenuProps {
  appearance: Appearance
  outfits: PresetOutfit[]
  onAppearanceChange: (appearance: Appearance) => void
}

type Tab = 'presets' | 'customize'

export function ClothingMenu({ appearance, outfits, onAppearanceChange }: ClothingMenuProps) {
  const [activeTab, setActiveTab] = useState<Tab>('presets')
  const [currentAppearance, setCurrentAppearance] = useState<Appearance>(appearance)

  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const handleAppearanceChange = (newAppearance: Appearance) => {
    setCurrentAppearance(newAppearance)
    onAppearanceChange(newAppearance)
    postNui('pd_clothing:updatePreview', { appearance: newAppearance })
  }

  const handlePresetSelect = (outfit: PresetOutfit) => {
    handleAppearanceChange(outfit.appearance)
  }

  const handleSave = async () => {
    await postNui('pd_clothing:save', { appearance: currentAppearance })
  }

  const handleCancel = async () => {
    await postNui('pd_clothing:close', {})
  }

  return (
    <div className="fixed inset-0 flex items-center justify-center z-50 p-4 pointer-events-auto bg-black/40">
      <div className="w-full max-w-6xl h-[90vh] flex flex-col">
        <div className="bg-[#1a1d29] rounded-2xl border-2 border-[#2d3142] shadow-2xl overflow-hidden flex flex-col h-full">
          <div className="p-6 border-b border-[#2d3142]">
            <h1 className="text-3xl font-bold text-white mb-2">Clothing Menu</h1>
            <p className="text-[#9ca3af]">Customize your character's appearance</p>
          </div>

          <div className="flex border-b border-[#2d3142]">
            <button
              type="button"
              onClick={() => {
                playClickSound()
                setActiveTab('presets')
              }}
              className={`flex-1 px-6 py-4 font-medium transition-all ${
                activeTab === 'presets'
                  ? 'bg-[#4a5f8f] text-white border-b-2 border-[#5a6f9a]'
                  : 'bg-[#252836] text-[#9ca3af] hover:bg-[#2d3142] hover:text-white'
              }`}
            >
              Preset Outfits
            </button>
            <button
              type="button"
              onClick={() => {
                playClickSound()
                setActiveTab('customize')
              }}
              className={`flex-1 px-6 py-4 font-medium transition-all ${
                activeTab === 'customize'
                  ? 'bg-[#4a5f8f] text-white border-b-2 border-[#5a6f9a]'
                  : 'bg-[#252836] text-[#9ca3af] hover:bg-[#2d3142] hover:text-white'
              }`}
            >
              Customize
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-6">
            {activeTab === 'presets' ? (
              <PresetSelector outfits={outfits} onSelect={handlePresetSelect} />
            ) : (
              <CustomizationPanel
                appearance={currentAppearance}
                onAppearanceChange={handleAppearanceChange}
              />
            )}
          </div>

          <div className="p-6 border-t border-[#2d3142]">
            <ActionButtons onSave={handleSave} onCancel={handleCancel} />
          </div>
        </div>
      </div>
    </div>
  )
}

