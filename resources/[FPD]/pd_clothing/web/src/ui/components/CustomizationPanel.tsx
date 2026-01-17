import { useState } from 'react'
import type { Appearance } from '../types'

interface CustomizationPanelProps {
  appearance: Appearance
  onAppearanceChange: (appearance: Appearance) => void
}

type Section = 'heritage' | 'hair' | 'face' | 'clothing'

export function CustomizationPanel({ appearance, onAppearanceChange }: CustomizationPanelProps) {
  const [activeSection, setActiveSection] = useState<Section>('heritage')

  const updateAppearance = (updates: Partial<Appearance>) => {
    onAppearanceChange({ ...appearance, ...updates })
  }

  const updateFeature = (key: string, value: number) => {
    const features = { ...appearance.features, [key]: value }
    updateAppearance({ features })
  }

  const updateComponent = (componentId: number, drawable: number, texture: number) => {
    const components = { ...appearance.components }
    components[componentId] = { drawable, texture }
    updateAppearance({ components })
  }

  const updateProp = (propId: number, drawable: number, texture: number) => {
    const props = { ...appearance.props }
    props[propId] = { drawable, texture }
    updateAppearance({ props })
  }

  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  return (
    <div className="flex gap-6 h-full">
      <div className="w-48 flex-shrink-0">
        <div className="bg-[#252836] rounded-lg p-2 space-y-1">
          {(['heritage', 'hair', 'face', 'clothing'] as Section[]).map((section) => (
            <button
              key={section}
              type="button"
              onClick={() => {
                playClickSound()
                setActiveSection(section)
              }}
              className={`w-full px-4 py-3 text-left rounded transition-all ${
                activeSection === section
                  ? 'bg-[#4a5f8f] text-white'
                  : 'text-[#9ca3af] hover:bg-[#2d3142] hover:text-white'
              }`}
            >
              {section.charAt(0).toUpperCase() + section.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {activeSection === 'heritage' && (
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold text-white mb-4">Parent & Heritage</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-[#d1d5db] mb-2">Mother</label>
                  <input
                    type="range"
                    min="0"
                    max="45"
                    value={appearance.mother || 0}
                    onChange={(e) => updateAppearance({ mother: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.mother || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Father</label>
                  <input
                    type="range"
                    min="0"
                    max="45"
                    value={appearance.father || 0}
                    onChange={(e) => updateAppearance({ father: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.father || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Skin Mix</label>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={((appearance.skinMix || 0.5) * 100).toFixed(0)}
                    onChange={(e) => updateAppearance({ skinMix: parseFloat(e.target.value) / 100 })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">
                    {((appearance.skinMix || 0.5) * 100).toFixed(0)}%
                  </div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Shape Mix</label>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={((appearance.shapeMix || 0.5) * 100).toFixed(0)}
                    onChange={(e) => updateAppearance({ shapeMix: parseFloat(e.target.value) / 100 })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">
                    {((appearance.shapeMix || 0.5) * 100).toFixed(0)}%
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeSection === 'hair' && (
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold text-white mb-4">Hair & Appearance</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-[#d1d5db] mb-2">Hair Style</label>
                  <input
                    type="range"
                    min="0"
                    max="73"
                    value={appearance.hairStyle || 0}
                    onChange={(e) => updateAppearance({ hairStyle: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.hairStyle || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Hair Color</label>
                  <input
                    type="range"
                    min="0"
                    max="63"
                    value={appearance.hairColor || 0}
                    onChange={(e) => updateAppearance({ hairColor: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.hairColor || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Hair Highlight</label>
                  <input
                    type="range"
                    min="0"
                    max="63"
                    value={appearance.hairHighlight || 0}
                    onChange={(e) => updateAppearance({ hairHighlight: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.hairHighlight || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Eye Color</label>
                  <input
                    type="range"
                    min="0"
                    max="31"
                    value={appearance.eyeColor || 0}
                    onChange={(e) => updateAppearance({ eyeColor: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.eyeColor || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Eyebrows</label>
                  <input
                    type="range"
                    min="0"
                    max="33"
                    value={appearance.eyebrows || 0}
                    onChange={(e) => updateAppearance({ eyebrows: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.eyebrows || 0}</div>
                </div>
                <div>
                  <label className="block text-[#d1d5db] mb-2">Beard</label>
                  <input
                    type="range"
                    min="0"
                    max="28"
                    value={appearance.beard || 0}
                    onChange={(e) => updateAppearance({ beard: parseInt(e.target.value) })}
                    className="w-full"
                  />
                  <div className="text-sm text-[#9ca3af] mt-1">{appearance.beard || 0}</div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeSection === 'face' && (
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold text-white mb-4">Facial Features</h3>
              <div className="space-y-4">
                {[
                  { key: 'noseWidth', label: 'Nose Width' },
                  { key: 'noseHeight', label: 'Nose Height' },
                  { key: 'noseLength', label: 'Nose Length' },
                  { key: 'noseBridge', label: 'Nose Bridge' },
                  { key: 'noseTip', label: 'Nose Tip' },
                  { key: 'noseShift', label: 'Nose Shift' },
                  { key: 'browHeight', label: 'Brow Height' },
                  { key: 'browWidth', label: 'Brow Width' },
                  { key: 'cheekboneHeight', label: 'Cheekbone Height' },
                  { key: 'cheekboneWidth', label: 'Cheekbone Width' },
                  { key: 'cheeksWidth', label: 'Cheeks Width' },
                  { key: 'eyes', label: 'Eyes' },
                  { key: 'lips', label: 'Lips' },
                  { key: 'jawWidth', label: 'Jaw Width' },
                  { key: 'jawHeight', label: 'Jaw Height' },
                  { key: 'chinLength', label: 'Chin Length' },
                  { key: 'chinPosition', label: 'Chin Position' },
                  { key: 'chinWidth', label: 'Chin Width' },
                  { key: 'chinShape', label: 'Chin Shape' },
                  { key: 'neckWidth', label: 'Neck Width' },
                ].map(({ key, label }) => (
                  <div key={key}>
                    <label className="block text-[#d1d5db] mb-2">{label}</label>
                    <input
                      type="range"
                      min="-100"
                      max="100"
                      value={((appearance.features?.[key as keyof typeof appearance.features] || 0) * 100).toFixed(0)}
                      onChange={(e) => updateFeature(key, parseFloat(e.target.value) / 100)}
                      className="w-full"
                    />
                    <div className="text-sm text-[#9ca3af] mt-1">
                      {((appearance.features?.[key as keyof typeof appearance.features] || 0) * 100).toFixed(0)}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {activeSection === 'clothing' && (
          <div className="space-y-6">
            <div>
              <h3 className="text-xl font-semibold text-white mb-4">Clothing Components</h3>
              <div className="space-y-4">
                {[
                  { id: 1, label: 'Face' },
                  { id: 2, label: 'Hair' },
                  { id: 3, label: 'Torso' },
                  { id: 4, label: 'Leg' },
                  { id: 5, label: 'Parachute/Bag' },
                  { id: 6, label: 'Shoes' },
                  { id: 7, label: 'Accessory' },
                  { id: 8, label: 'Undershirt' },
                  { id: 9, label: 'Kevlar' },
                  { id: 10, label: 'Badge' },
                  { id: 11, label: 'Torso2' },
                ].map(({ id, label }) => {
                  const component = appearance.components?.[id] || { drawable: 0, texture: 0 }
                  return (
                    <div key={id} className="bg-[#252836] p-4 rounded-lg">
                      <h4 className="text-white font-medium mb-3">{label}</h4>
                      <div className="space-y-2">
                        <div>
                          <label className="block text-[#d1d5db] text-sm mb-1">Drawable</label>
                          <input
                            type="range"
                            min="0"
                            max="200"
                            value={component.drawable}
                            onChange={(e) => updateComponent(id, parseInt(e.target.value), component.texture)}
                            className="w-full"
                          />
                          <div className="text-xs text-[#9ca3af] mt-1">{component.drawable}</div>
                        </div>
                        <div>
                          <label className="block text-[#d1d5db] text-sm mb-1">Texture</label>
                          <input
                            type="range"
                            min="0"
                            max="20"
                            value={component.texture}
                            onChange={(e) => updateComponent(id, component.drawable, parseInt(e.target.value))}
                            className="w-full"
                          />
                          <div className="text-xs text-[#9ca3af] mt-1">{component.texture}</div>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            <div>
              <h3 className="text-xl font-semibold text-white mb-4">Props (Accessories)</h3>
              <div className="space-y-4">
                {[
                  { id: 0, label: 'Hat' },
                  { id: 1, label: 'Glasses' },
                  { id: 2, label: 'Ear' },
                  { id: 6, label: 'Watch' },
                  { id: 7, label: 'Bracelet' },
                ].map(({ id, label }) => {
                  const prop = appearance.props?.[id] || { drawable: -1, texture: 0 }
                  return (
                    <div key={id} className="bg-[#252836] p-4 rounded-lg">
                      <h4 className="text-white font-medium mb-3">{label}</h4>
                      <div className="space-y-2">
                        <div>
                          <label className="block text-[#d1d5db] text-sm mb-1">Drawable (-1 to remove)</label>
                          <input
                            type="range"
                            min="-1"
                            max="200"
                            value={prop.drawable}
                            onChange={(e) => updateProp(id, parseInt(e.target.value), prop.texture)}
                            className="w-full"
                          />
                          <div className="text-xs text-[#9ca3af] mt-1">{prop.drawable}</div>
                        </div>
                        {prop.drawable !== -1 && (
                          <div>
                            <label className="block text-[#d1d5db] text-sm mb-1">Texture</label>
                            <input
                              type="range"
                              min="0"
                              max="20"
                              value={prop.texture}
                              onChange={(e) => updateProp(id, prop.drawable, parseInt(e.target.value))}
                              className="w-full"
                            />
                            <div className="text-xs text-[#9ca3af] mt-1">{prop.texture}</div>
                          </div>
                        )}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

