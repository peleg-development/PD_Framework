import { useEffect } from 'react'
import { postNui } from '../nui'
import type { PDCharacter } from '../types'

interface CharacterPreviewProps {
  character: PDCharacter | null
  className?: string
}

const MALE_PEDS = [
  'mp_m_freemode_01',
  's_m_y_cop_01',
  's_m_y_fireman_01',
  's_m_y_swat_01',
  's_m_m_paramedic_01',
]

const FEMALE_PEDS = [
  'mp_f_freemode_01',
  's_f_y_cop_01',
  's_f_y_fireman_01',
  's_f_y_swat_01',
  's_f_m_paramedic_01',
]

export function CharacterPreview({ character, className = '' }: CharacterPreviewProps) {
  useEffect(() => {
    let model = ''
    
    if (!character) {
      const randomMale = MALE_PEDS[Math.floor(Math.random() * MALE_PEDS.length)]
      model = randomMale
    } else {
      const models = character.gender === 'female' ? FEMALE_PEDS : MALE_PEDS
      model = models[Math.floor(Math.random() * models.length)]
    }

    if (model) {
      postNui('pd_char:updatePreviewPed', { model })
    }

    return () => {
      postNui('pd_char:updatePreviewPed', { model: '' })
    }
  }, [character])

  return (
    <div className={`relative ${className} flex items-center justify-center bg-slate-900/40 rounded-lg border border-slate-700/30`}>
      <div className="text-center p-8">
        <p className="text-slate-400 text-sm mb-2">Character Preview</p>
        {character && (
          <p className="text-slate-300 text-lg font-medium">
            {character.firstName} {character.lastName}
          </p>
        )}
        <p className="text-slate-500 text-xs mt-2">
          Look at your game screen to see the ped
        </p>
      </div>
    </div>
  )
}
