import { useCallback, useRef } from 'react'
import { NotifyStack } from './components/NotifyStack'
import { ContextMenu } from './components/ContextMenu'
import { ProgressBar } from './components/ProgressBar'
import { DialogueOverlay } from './components/DialogueOverlay'
import { ResultOverlay } from './components/ResultOverlay'
import { useNuiMessages } from './useNuiMessages'
import type { ContextData, DialogueLine, DialogueOpenData, NotifyData, NuiMessage, ProgressData, ResultData } from './types'

export function App() {
  const notifyPush = useRef<(data: NotifyData) => void>(() => {})
  const ctxOpen = useRef<(origin: string, ctx: ContextData) => void>(() => {})
  const ctxClose = useRef<() => void>(() => {})
  const progressStart = useRef<(origin: string, id: string, data: ProgressData) => void>(() => {})
  const dialogueOpen = useRef<(origin: string, data: DialogueOpenData) => void>(() => {})
  const dialoguePush = useRef<(origin: string, data: DialogueLine) => void>(() => {})
  const dialogueClose = useRef<() => void>(() => {})
  const resultShow = useRef<(origin: string, data: ResultData) => void>(() => {})
  const resultClose = useRef<() => void>(() => {})

  const onMsg = useCallback((msg: NuiMessage) => {
    if (msg.type === 'notify:add') {
      notifyPush.current(msg.data)
      return
    }
    if (msg.type === 'context:open') {
      ctxOpen.current(msg.origin, msg.context)
      return
    }
    if (msg.type === 'context:close') {
      ctxClose.current()
      return
    }
    if (msg.type === 'progress:start') {
      progressStart.current(msg.origin, msg.id, msg.data)
      return
    }
    if (msg.type === 'progress:end') {
      return
    }
    if (msg.type === 'dialogue:open') {
      dialogueOpen.current(msg.origin, msg.data)
      return
    }
    if (msg.type === 'dialogue:push') {
      dialoguePush.current(msg.origin, msg.data)
      return
    }
    if (msg.type === 'dialogue:close') {
      dialogueClose.current()
      return
    }
    if (msg.type === 'result:show') {
      resultShow.current(msg.origin, msg.data)
      return
    }
    if (msg.type === 'result:close') {
      resultClose.current()
      return
    }
  }, [])

  useNuiMessages(onMsg)

  return (
    <>
      <NotifyStack pushRef={(fn) => (notifyPush.current = fn)} />
      <ContextMenu
        openRef={(openFn, closeFn) => {
          ctxOpen.current = openFn
          ctxClose.current = closeFn
        }}
      />
      <ProgressBar startRef={(fn) => (progressStart.current = fn)} />
      <DialogueOverlay
        apiRef={(openFn, pushFn, closeFn) => {
          dialogueOpen.current = openFn
          dialoguePush.current = pushFn
          dialogueClose.current = closeFn
        }}
      />
      <ResultOverlay
        apiRef={(showFn, closeFn) => {
          resultShow.current = showFn
          resultClose.current = closeFn
        }}
      />
    </>
  )
}


