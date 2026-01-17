export function getNuiResourceName() {
  const fn = (window as any).GetParentResourceName
  if (typeof fn === 'function') return fn()
  return 'pd_lib'
}

export async function postNui<T = any>(callbackName: string, payload: any): Promise<T> {
  const resName = getNuiResourceName()
  const resp = await fetch(`https://${resName}/${callbackName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload ?? {}),
  })
  try {
    return (await resp.json()) as T
  } catch {
    return {} as T
  }
}


