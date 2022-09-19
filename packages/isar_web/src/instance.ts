import { IsarCollection } from './collection'
import { LinkSchema, Schema } from './schema'
import { IsarTxn } from './txn'
import { ChangeSet } from './watcher'
import { BroadcastChannel } from 'broadcast-channel'

export const idName = '_id';

export class IsarInstance {
  private static readonly bc = new BroadcastChannel('ISAR_CHANNEL')

  private readonly db: IDBDatabase
  private readonly relaxedDurability: boolean
  private collections: Map<string, IsarCollection<any>> = new Map()
  private eventHandler: EventListener

  constructor(db: IDBDatabase, relaxedDurability: boolean, schemas: Schema[]) {
    this.db = db
    this.relaxedDurability = relaxedDurability
    this.initializeCollections(schemas)

    this.eventHandler = (event: MessageEvent) => {
      if (
        event.data &&
        event.data.type === 'change' &&
        event.data.instance == this.db.name
      ) {
        this.notifyWatchers(event.data.changes, true)
      }
    }
    IsarInstance.bc.addEventListener('message', this.eventHandler)
  }

  private initializeCollections(schemas: Schema[]) {
    for (let schema of schemas) {
      const backlinkStoreNames = schemas.flatMap(s => {
        if (s.name === schema.name) {
          return []
        }
        return s.links
          .filter(l => l.target === schema.name)
          .map(l => {
            return LinkSchema.getStoreName(s.name, l.target, l.name)
          })
      })
      const col = new IsarCollection(this, schema, backlinkStoreNames)
      this.collections.set(schema.name, col)
    }
  }

  notifyWatchers(
    changes: Map<string, ChangeSet<any>>,
    external: boolean = false,
  ) {
    let txn: IsarTxn | undefined

    const getTxn = () => {
      if (txn == null) {
        txn = this.beginTxn(false)
      }
      return txn!
    }
    for (let [colName, changeSet] of changes.entries()) {
      const collection = this.getCollection(colName)
      collection.notify(changeSet, getTxn)
    }

    if (!external) {
      const event: ChangeEvent = {
        type: 'change',
        instance: this.db.name,
        changes,
      }
      IsarInstance.bc.postMessage(event)
    }
  }

  beginTxn(write: boolean): IsarTxn {
    const names = this.db.objectStoreNames
    const mode = write ? 'readwrite' : 'readonly'
    const options = this.relaxedDurability ? { durability: 'relaxed' } : {}
    const txn = (this.db as any).transaction(names, mode, options)
    return new IsarTxn(this, txn, write)
  }

  getCollection<OBJ>(name: string): IsarCollection<OBJ> {
    return this.collections.get(name)!
  }

  close(deleteFromDisk: boolean = false): Promise<void> {
    IsarInstance.bc.removeEventListener('message', this.eventHandler)
    this.db.close()
    if (deleteFromDisk) {
      const req = indexedDB.deleteDatabase(this.db.name)
      return new Promise((resolve, reject) => {
        req.onsuccess = () => {
          resolve()
        }
        req.onerror = () => {
          reject(req.error)
        }
      })
    } else {
      return Promise.resolve()
    }
  }
}

type ChangeEvent = {
  type: 'change'
  instance: string
  changes: Map<string, ChangeSet<any>>
}
