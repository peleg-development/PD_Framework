export interface Appearance {
  mother?: number
  father?: number
  skinMix?: number
  shapeMix?: number
  features?: {
    noseWidth?: number
    noseHeight?: number
    noseLength?: number
    noseBridge?: number
    noseTip?: number
    noseShift?: number
    browHeight?: number
    browWidth?: number
    cheekboneHeight?: number
    cheekboneWidth?: number
    cheeksWidth?: number
    eyes?: number
    lips?: number
    jawWidth?: number
    jawHeight?: number
    chinLength?: number
    chinPosition?: number
    chinWidth?: number
    chinShape?: number
    neckWidth?: number
  }
  hairStyle?: number
  hairColor?: number
  hairHighlight?: number
  eyeColor?: number
  eyebrows?: number
  eyebrowColor?: number
  beard?: number
  beardColor?: number
  beardOpacity?: number
  makeup?: number
  makeupColor?: number
  makeupOpacity?: number
  blush?: number
  blushColor?: number
  blushOpacity?: number
  lipstick?: number
  lipstickColor?: number
  lipstickOpacity?: number
  components?: Record<number, { drawable: number; texture: number }>
  props?: Record<number, { drawable: number; texture: number }>
  tattoos?: Array<{
    collection: string
    name: string
    zone?: string
    overlay?: number
  }>
  overlays?: {
    blemishes?: { style: number; opacity: number }
    blemishesColor?: { style: number; opacity: number }
    ageing?: { style: number; opacity: number }
    makeup?: { style: number; opacity: number }
  }
}

export interface PresetOutfit {
  name: string
  label: string
  appearance: Appearance
}

export interface NuiMessage {
  type: string
  appearance?: Appearance
  outfits?: PresetOutfit[]
}

