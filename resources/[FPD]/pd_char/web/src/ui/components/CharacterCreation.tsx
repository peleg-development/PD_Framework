import { useState } from 'react'
import { postNui } from '../nui'
import { DatePicker } from './DatePicker'

interface CharacterCreationProps {
  slot: number
  maxSlots: number
  onCancel: () => void
  onCreated: () => void
}

export function CharacterCreation({ slot, maxSlots, onCancel, onCreated }: CharacterCreationProps) {
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [dateOfBirth, setDateOfBirth] = useState('')
  const [gender, setGender] = useState<'male' | 'female'>('male')
  const [isCreating, setIsCreating] = useState(false)

  const playClickSound = () => {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIGWi77+efTRAMUKfj8LZjHAY4kdfyzHksBSR3x/DdkEAKFF606euoVRQKRp/g8r5sIQUrgc7y2Yk2CBlou+/nn00QDFCn4/C2YxwGOJHX8sx5LAUkd8fw3ZBAC')
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  const handleCreate = async () => {
    if (!firstName.trim() || !lastName.trim()) {
      alert('Please enter both first and last name')
      return
    }

    playClickSound()
    setIsCreating(true)
    try {
      await postNui('pd_char:createCharacter', {
        slot,
        data: {
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          dateOfBirth: dateOfBirth.trim(),
          gender,
        },
      })
    } catch (error) {
      console.error('Failed to create character:', error)
      setIsCreating(false)
    }
  }


  const previewCharacter = {
    id: 0,
    identifier: '',
    slot,
    firstName,
    lastName,
    dateOfBirth,
    gender,
    appearance: {},
    metadata: {},
    createdAt: 0,
    updatedAt: 0,
  }

  return (
    <div className="fixed inset-0 flex items-center justify-center z-50 p-4 pointer-events-auto bg-black/40">
      <div className="w-full max-w-2xl">
        <div className="bg-[#1a1d29] rounded-2xl border-2 border-[#2d3142] shadow-2xl overflow-visible">
          <div className="p-8">
            <div className="mb-8">
              <h2 className="text-3xl font-bold text-white mb-2">Create Your Character</h2>
              <p className="text-[#9ca3af]">Fill in your character information to get started</p>
            </div>
            
            <div className="space-y-5">
              <div>
                <label className="block text-[#d1d5db] mb-2 text-sm font-medium">First Name</label>
                <input
                  type="text"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full px-4 py-3 bg-[#252836] text-white rounded-lg border border-[#3d4254] focus:border-[#5a6f9a] focus:outline-none focus:ring-2 focus:ring-[#5a6f9a] transition-all placeholder:text-[#6b7280]"
                  placeholder="John"
                  disabled={isCreating}
                />
              </div>

              <div>
                <label className="block text-[#d1d5db] mb-2 text-sm font-medium">Last Name</label>
                <input
                  type="text"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full px-4 py-3 bg-[#252836] text-white rounded-lg border border-[#3d4254] focus:border-[#5a6f9a] focus:outline-none focus:ring-2 focus:ring-[#5a6f9a] transition-all placeholder:text-[#6b7280]"
                  placeholder="Doe"
                  disabled={isCreating}
                />
              </div>

              <div>
                <label className="block text-[#d1d5db] mb-2 text-sm font-medium">Date of Birth</label>
                <DatePicker
                  value={dateOfBirth}
                  onChange={setDateOfBirth}
                  disabled={isCreating}
                />
              </div>

              <div>
                <label className="block text-[#d1d5db] mb-2 text-sm font-medium">Gender</label>
                <div className="flex gap-0">
                  <button
                    type="button"
                    onClick={() => {
                      playClickSound()
                      setGender('male')
                    }}
                    disabled={isCreating}
                    className={`flex-1 px-4 py-3 font-medium transition-all ${
                      gender === 'male'
                        ? 'bg-[#4a5f8f] text-white border-2 border-[#5a6f9a]'
                        : 'bg-[#252836] text-[#9ca3af] border-2 border-[#3d4254] hover:border-[#4a5f8f] hover:text-white'
                    } ${gender === 'male' ? 'rounded-l-lg rounded-r-none' : 'rounded-none'} ${!isCreating && 'cursor-pointer'}`}
                  >
                    Male
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      playClickSound()
                      setGender('female')
                    }}
                    disabled={isCreating}
                    className={`flex-1 px-4 py-3 font-medium transition-all ${
                      gender === 'female'
                        ? 'bg-[#4a5f8f] text-white border-2 border-[#5a6f9a]'
                        : 'bg-[#252836] text-[#9ca3af] border-2 border-[#3d4254] hover:border-[#4a5f8f] hover:text-white'
                    } ${gender === 'female' ? 'rounded-r-lg rounded-l-none' : 'rounded-none'} ${!isCreating && 'cursor-pointer'}`}
                  >
                    Female
                  </button>
                </div>
              </div>
            </div>

            <div className="mt-8">
              <button
                onClick={handleCreate}
                disabled={isCreating || !firstName.trim() || !lastName.trim()}
                className="w-full px-6 py-4 bg-[#4a5f8f] hover:bg-[#5a6f9a] disabled:bg-[#252836] disabled:cursor-not-allowed disabled:text-[#6b7280] text-white rounded-lg font-semibold text-lg transition-all duration-200"
              >
                {isCreating ? 'Creating Character...' : 'Create Character'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

