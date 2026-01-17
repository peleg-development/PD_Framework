export type CalloutInfo = {
  name: string
  code: string
  title: string
  description: string
  department?: string
  minRank?: number
}

export type OfferMessage = {
  type: 'offer'
  id: string
  callout: CalloutInfo
  distance?: number
  timeoutMs: number
}

export type HideMessage = {
  type: 'hide'
}

export type NuiMessage = OfferMessage | HideMessage


