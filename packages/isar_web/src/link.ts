import { bulkDelete } from './bulk-delete'
import { IsarInstance } from './instance'
import { LinkSchema } from './schema'
import { IsarTxn } from './txn'

export class IsarLink {
  static readonly BacklinkIndex = 'backlink'

  readonly isar: IsarInstance
  readonly name: string
  readonly sourceName: string
  readonly targetName: string
  readonly storeName: string

  constructor(
    isar: IsarInstance,
    name: string,
    sourceName: string,
    targetName: string,
  ) {
    this.isar = isar
    this.name = name
    this.sourceName = sourceName
    this.targetName = targetName
    this.storeName = LinkSchema.getStoreName(sourceName, targetName, name)
  }

  private getLinkEntry(source: number, target: number, backlink: boolean): any {
    if (backlink) {
      ;[source, target] = [target, source]
    }
    return {
      a: source,
      b: target,
    }
  }

  static getLinkKeyRange(id: number): IDBKeyRange {
    return IDBKeyRange.bound([id, -Infinity], [id, Infinity])
  }

  update(
    txn: IsarTxn,
    backlink: boolean,
    id: number,
    addedTargets: number[],
    deletedTargets: number[],
  ): Promise<void> {
    if (addedTargets.length === 0 && deletedTargets.length === 0) {
      return Promise.resolve()
    }

    return new Promise((resolve, reject) => {
      const store = txn.txn.objectStore(this.storeName)

      const deletedEmpty = deletedTargets.length === 0
      for (let i = 0; i < addedTargets.length; i++) {
        let target = addedTargets[i]
        const req = store.add(this.getLinkEntry(id, target, backlink))
        if (deletedEmpty && i === addedTargets.length - 1) {
          req.onsuccess = () => {
            resolve()
          }
        }
        req.onerror = () => {
          txn.abort()
          reject(req.error)
        }
      }

      for (let i = 0; i < deletedTargets.length; i++) {
        let target = deletedTargets[i]
        const key = backlink ? [target, id] : [id, target]
        const req = store.delete(key)
        if (i === deletedTargets.length - 1) {
          req.onsuccess = () => {
            resolve()
          }
        }
        req.onerror = () => {
          txn.abort()
          reject(req.error)
        }
      }
    })
  }

  clear(txn: IsarTxn, id: number, backlink: boolean): Promise<void> {
    return new Promise((resolve, reject) => {
      const store = txn.txn.objectStore(this.storeName)
      if (backlink) {
        const keysRes = store.index(IsarLink.BacklinkIndex).getAllKeys(id)
        keysRes.onsuccess = () => {
          const keys = keysRes.result
          if (keys.length > 0) {
            const ids = keys.map(key => (key as number[])[1])
            bulkDelete(txn, this.storeName, ids).then(resolve, reject)
          } else {
            resolve()
          }
        }
        keysRes.onerror = () => {
          txn.abort()
          reject(keysRes.error)
        }
      } else {
        const deleteReq = store.delete(IsarLink.getLinkKeyRange(id))
        deleteReq.onsuccess = () => {
          resolve()
        }
        deleteReq.onerror = () => {
          txn.abort()
          reject(deleteReq.error)
        }
      }
    })
  }
}
