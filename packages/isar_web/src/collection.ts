import { bulkDelete, bulkDeleteByIndex } from './bulk-delete'
import { idName, IsarInstance } from './instance'
import { IsarLink } from './link'
import { IndexSchema, IsarType, Schema } from './schema'
import { IsarTxn } from './txn'
import { IsarWatchable } from './watcher'

interface UniqueIndex {
  readonly name: string
  readonly accessors: string[]
}

export type IndexKey = string | number | IndexKey[]

export class IsarCollection<OBJ> extends IsarWatchable<OBJ> {
  readonly isar: IsarInstance
  readonly name: string
  private readonly uniqueIndexes: ReadonlyArray<UniqueIndex>
  private readonly links: ReadonlyArray<IsarLink>
  // only backlinks that don't target this collection
  private readonly backlinkStoreNames: ReadonlyArray<string>
  private readonly multiEntryIndexes: string[]
  private readonly indexKeyPaths = new Map<string, string[]>()

  constructor(
    isar: IsarInstance,
    schema: Schema,
    backlinkStoreNames: string[],
  ) {
    super()
    this.isar = isar
    this.name = schema.name
    this.uniqueIndexes = schema.indexes
      .filter(i => i.unique)
      .map(i => ({
        name: i.name,
        accessors: i.properties.map(p => p.name),
      }))
    this.links = schema.links.map(
      l => new IsarLink(isar, l.name, schema.name, l.target),
    )
    this.backlinkStoreNames = backlinkStoreNames
    this.multiEntryIndexes = schema.indexes
      .filter(i => IndexSchema.isIndexMultiEntry(schema, i))
      .map(i => i.name)
    this.indexKeyPaths = new Map(
      schema.indexes.map(i => [i.name, i.properties.map(p => p.name)]),
    )
  }

  getLink(name: string): IsarLink | undefined {
    return this.links.find(l => l.name === name)
  }

  getIndexKeyPath(indexName: string): string[] {
    return this.indexKeyPaths.get(indexName)!
  }

  isMultiEntryIndex(indexName: string): boolean {
    return this.multiEntryIndexes.includes(indexName)
  }

  get(txn: IsarTxn, id: number): Promise<OBJ | undefined> {
    let store = txn.txn.objectStore(this.name)
    return new Promise((resolve, reject) => {
      let req = store.get(id)
      req.onsuccess = () => {
        const object = req.result
        if (object) {
          object[idName] = id
        }
        resolve(object)
      }
      req.onerror = () => {
        reject(req.error)
      }
    })
  }

  getAll(txn: IsarTxn, ids: number[]): Promise<(OBJ | undefined)[]> {
    return new Promise((resolve, reject) => {
      const store = txn.txn.objectStore(this.name)
      const results: (OBJ | undefined)[] = []
      for (let i = 0; i < ids.length; i++) {
        const id = ids[i]
        const req = store.get(id)
        req.onsuccess = () => {
          const object = req.result
          if (object) {
            object[idName] = id
          }
          results.push(object)
          if (results.length == ids.length) {
            resolve(results)
          }
        }
        req.onerror = () => {
          reject(req.error)
        }
      }
    })
  }

  getAllByIndex(
    txn: IsarTxn,
    indexName: string,
    keys: IndexKey[],
  ): Promise<(OBJ | undefined)[]> {
    if (keys.length === 0) {
      return Promise.resolve([])
    }

    keys.sort(indexedDB.cmp)
    return new Promise((resolve, reject) => {
      const store = txn.txn.objectStore(this.name)
      const results: (OBJ | undefined)[] = []
      const cursorReq = store.index(indexName).openCursor()
      cursorReq.onsuccess = () => {
        const cursor = cursorReq.result
        if (cursor) {
          const object = cursor.value
          if (results.length > 0 || cursor.key === keys[0]) {
            if (object) {
              object[idName] = cursor.primaryKey
              results.push(object)
            } else {
              results.push(undefined)
            }
          }
          if (results.length == keys.length) {
            resolve(results)
          } else {
            cursor.continue(keys[results.length])
          }
        } else {
          resolve([])
        }
      }
      cursorReq.onerror = e => {
        reject(e)
      }
    })
  }

  putAll(txn: IsarTxn, objects: OBJ[]): Promise<number[]> {
    let store = txn.txn.objectStore(this.name)
    return new Promise((resolve, reject) => {
      const ids: (number | undefined)[] = []
      const changeSet = txn.getChangeSet(this.name)
      for (let i = 0; i < objects.length; i++) {
        const object = objects[i] as any
        const id = object[idName]

        const req = store.put(object)
        delete object[idName]

        ids.push(id)
        if (!id) {
          req.onsuccess = () => {
            const id = req.result as number
            ids[i] = id
            changeSet.registerChange(id, object)
            if (i === objects.length - 1) {
              resolve(ids as number[])
            }
          }
        } else {
          changeSet.registerChange(id, object)
          if (i === objects.length - 1) {
            req.onsuccess = () => {
              resolve(ids as number[])
            }
          }
        }
        req.onerror = () => {
          txn.abort()
          reject(req.error)
        }
      }
    })
  }

  private deleteLinks(txn: IsarTxn, keys: IDBValidKey[]): Promise<void> {
    if (this.links.length === 0 && this.backlinkStoreNames.length === 0) {
      return Promise.resolve()
    }
    const linkPromises = this.links.map(l => {
      return bulkDelete(txn, l.storeName, keys.map(IsarLink.getLinkKeyRange))
    })
    const backlinkPromises = this.backlinkStoreNames.map(storeName => {
      return bulkDeleteByIndex(txn, storeName, IsarLink.BacklinkIndex, keys)
    })
    return Promise.all([...linkPromises, ...backlinkPromises]).then(() => { })
  }

  deleteAll(txn: IsarTxn, ids: number[]): Promise<void> {
    return bulkDelete(txn, this.name, ids).then(() => {
      const changeSet = txn.getChangeSet(this.name)
      for (let id of ids) {
        changeSet.registerChange(id)
      }
      return this.deleteLinks(txn, ids)
    })
  }

  deleteAllByIndex(
    txn: IsarTxn,
    indexName: string,
    keys: IndexKey[],
  ): Promise<number> {
    return bulkDeleteByIndex(txn, this.name, indexName, keys).then(ids => {
      const changeSet = txn.getChangeSet(this.name)
      for (let id of ids as number[]) {
        changeSet.registerChange(id)
      }
      return this.deleteLinks(txn, ids).then(() => ids.length)
    })
  }

  clear(txn: IsarTxn): Promise<void> {
    return new Promise((resolve, reject) => {
      const storeNames = [
        this.name,
        ...this.backlinkStoreNames,
        ...this.links.map(l => l.storeName),
      ]
      for (let i = 0; i < storeNames.length; i++) {
        const store = txn.txn.objectStore(this.name)
        const req = store.clear()
        req.onerror = () => {
          reject(req.error)
        }
        if (i === storeNames.length - 1) {
          req.onsuccess = () => {
            txn.getChangeSet(this.name).registerCleared()
            resolve()
          }
        }
      }
    })
  }
}
