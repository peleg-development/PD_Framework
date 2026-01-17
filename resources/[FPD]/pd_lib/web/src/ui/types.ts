export type NotifyType = 'info' | 'success' | 'warning' | 'error'

export type NotifyData = {
  title?: string
  description?: string
  type?: NotifyType
  duration?: number
  position?: string
}

export type ContextOption = {
  id: string
  title: string
  description?: string
  disabled?: boolean
  color?: string
  value?: string
  valueColor?: string
  values?: string[]
  valueIndex?: number
}

export type ContextData = {
  id: string
  title: string
  description?: string
  focus?: boolean
  options: ContextOption[]
}

export type ProgressData = {
  duration: number
  label: string
  canCancel?: boolean
}

export type DialogueSide = 'you' | 'ped' | 'system'

export type DialogueOpenData = {
  title?: string
  subtitle?: string
  reset?: boolean
  duration?: number
}

export type DialogueLine = {
  side: DialogueSide
  name?: string
  text: string
}

export type ResultKind = 'idcard' | 'pedcheck' | 'vehiclecheck' | 'search' | 'generic'

export type ResultField = {
  label: string
  value: string
  color?: string
}

export type ResultData = {
  kind: ResultKind
  title: string
  subtitle?: string
  fields: ResultField[]
  duration?: number
}

export type NuiMessage =
  | { type: 'notify:add'; origin: string; data: NotifyData }
  | { type: 'context:open'; origin: string; context: ContextData }
  | { type: 'context:close' }
  | { type: 'progress:start'; origin: string; id: string; data: ProgressData }
  | { type: 'progress:end'; id: string }
  | { type: 'dialogue:open'; origin: string; data: DialogueOpenData }
  | { type: 'dialogue:push'; origin: string; data: DialogueLine }
  | { type: 'dialogue:close' }
  | { type: 'result:show'; origin: string; data: ResultData }
  | { type: 'result:close' }


