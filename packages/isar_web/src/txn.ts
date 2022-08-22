import { IsarInstance } from './instance'
import { IsarChangeSet } from './watcher'

export class IsarTxn {
  readonly isar: IsarInstance
  readonly txn: IDBTransaction
  active: boolean
  readonly write: boolean
  private readonly changes: Map<string, IsarChangeSet<any>> | undefined

  constructor(isar: IsarInstance, txn: IDBTransaction, write: boolean) {
    this.isar = isar
    this.txn = txn
    this.active = true
    this.write = write

    if (write) {
      this.changes = new Map()
    }
  }

  getChangeSet<OBJ>(collectionName: string): IsarChangeSet<OBJ> {
    let changeSet = this.changes!.get(collectionName)
    if (changeSet == null) {
      changeSet = new IsarChangeSet()
      this.changes!.set(collectionName, changeSet)
    }
    return changeSet
  }

  commit(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.active = false

      this.txn.oncomplete = () => {
        if (this.changes) {
          this.isar.notifyWatchers(this.changes)
        }
        resolve()
      }
      this.txn.onerror = () => {
        reject(this.txn.error)
      }
      this.txn.commit()
    })
  }

  abort() {
    if (this.active) {
      this.active = false
      this.txn.abort()
    }
  }
}
