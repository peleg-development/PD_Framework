export interface PDCharacter {
  id: number
  identifier: string
  slot: number
  firstName: string
  lastName: string
  dateOfBirth: string
  gender: string
  appearance: Record<string, any>
  metadata: Record<string, any>
  createdAt: number
  updatedAt: number
}

export interface SpawnLocation {
  name: string
  x: number
  y: number
  z: number
  heading: number
}

export interface NuiMessage {
  type: string
  characters?: PDCharacter[]
  character?: PDCharacter
  maxCharacters?: number
  spawnLocations?: SpawnLocation[]
}
