import { IsarTxn } from './txn'

export function bulkDelete(
  txn: IsarTxn,
  storeName: string,
  keys: (IDBValidKey | IDBKeyRange)[],
): Promise<void> {
  return new Promise((resolve, reject) => {
    const len = keys.length
    const lastItem = len - 1
    if (len === 0) return resolve()
    const store = txn.txn.objectStore(storeName)
    for (let i = 0; i < keys.length; i++) {
      const req = store.delete(keys[i])
      req.onerror = () => {
        txn.abort()
        reject(req.error)
      }
      if (i === lastItem) {
        req.onsuccess = () => {
          resolve()
        }
      }
    }
  })
}

export function bulkDeleteByIndex(
  txn: IsarTxn,
  storeName: string,
  indexName: string,
  keys: IDBValidKey[],
): Promise<IDBValidKey[]> {
  if (keys.length === 0) return Promise.resolve([])
  return new Promise((resolve, reject) => {
    const store = txn.txn.objectStore(storeName)
    const index = store.index(indexName)

    const primaryKeys: IDBValidKey[] = []
    for (var i = 0; i < keys.length; i++) {
      const indexReq = index.getAllKeys(keys[i])
      const isLast = i === keys.length - 1
      indexReq.onsuccess = () => {
        primaryKeys.push(...indexReq.result)
        if (isLast) {
          bulkDelete(txn, storeName, primaryKeys).then(
            () => resolve(primaryKeys),
            reject,
          )
        }
      }
      indexReq.onerror = () => {
        txn.abort()
        reject(indexReq.error)
      }
    }
  })
}
