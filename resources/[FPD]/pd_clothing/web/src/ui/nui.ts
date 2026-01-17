/**
 * @param callbackName Name of the NUI callback to invoke
 * @param payload Data to send to the callback
 */
export async function postNui<T = any>(callbackName: string, payload: any): Promise<T> {
  return new Promise<T>((resolve) => {
    fetch(`https://${GetParentResourceName()}/${callbackName}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
      .then((res) => res.json())
      .then((data) => resolve(data as T))
      .catch(() => resolve({ ok: false } as T))
  })
}

declare function GetParentResourceName(): string

