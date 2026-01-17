import { useEffect } from 'react'
import type { NuiMessage } from './types'

export function useNuiMessages(handler: (msg: NuiMessage) => void) {
  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const data = event.data as NuiMessage
      if (!data || typeof data !== 'object' || !('type' in data)) return
      handler(data)
    }
    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [handler])
}


