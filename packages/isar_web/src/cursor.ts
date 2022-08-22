import { IsarTxn } from './txn'

type CursorParams = {
  txn: IsarTxn
  callback: CursorCallback
  storeName: string
  indexName?: string
  range?: IDBKeyRange
  offset?: number
  direction?: IDBCursorDirection
}

type CursorCallback = (
  id: any,
  value: any,
  next: Function,
  resolve: Function,
  reject: Function,
) => void

export function useCursor(params: CursorParams): Promise<void> {
  return new Promise((resolve, reject) => {
    const store = params.txn.txn.objectStore(params.storeName)
    const source =
      params.indexName != null ? store.index(params.indexName) : store
    const multiEntry = params.indexName && (source as IDBIndex).multiEntry

    const cursorReq = source.openCursor(params.range, params.direction)
    cursorReq.onsuccess = () => {
      const cursor = cursorReq.result
      if (cursor) {
        if (params.offset) {
          cursor.advance(params.offset)
          params.offset = undefined
        } else {
          if (multiEntry) {
            const isArray = Array.isArray(
              cursor.value[source.keyPath as string],
            )
            if (!isArray) {
              cursor.continue()
              return
            }
          }
          params.callback(
            cursor.primaryKey,
            cursor.value,
            function () {
              cursor.continue()
            },
            resolve,
            reject,
          )
        }
      } else {
        resolve()
      }
    }
    cursorReq.onerror = e => {
      reject(e)
    }
  })
}
