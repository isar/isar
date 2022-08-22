import { bulkDelete, bulkDeleteByIndex } from './bulk-delete'
import { idb2Obj, obj2Idb, val2Idb } from './helper'
import { IsarInstance } from './instance'
import { IsarLink } from './link'
import { IndexSchema, IsarType, Schema } from './schema'
import { IsarTxn } from './txn'
import { IsarWatchable } from './watcher'

interface UniqueIndex {
  readonly name: string
  readonly accessors: string[]
}

export type IndexKey = string | number | boolean | IndexKey[]

export class IsarCollection<OBJ> extends IsarWatchable<OBJ> {
  readonly isar: IsarInstance
  readonly name: string
  readonly idName: string
  private readonly boolValues: string[]
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
    this.idName = schema.idName
    this.boolValues = schema.properties
      .filter(p => p.type == IsarType.Bool || p.type == IsarType.BoolList)
      .map(p => p.name)
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

  toObject(obj: any): OBJ {
    return idb2Obj(obj, this.boolValues)
  }

  getId(obj: OBJ): number {
    return (obj as any)[this.idName]
  }

  getIndexKeyPath(indexName: string): string[] {
    return this.indexKeyPaths.get(indexName)!
  }

  isMultiEntryIndex(indexName: string): boolean {
    return this.multiEntryIndexes.includes(indexName)
  }

  private prepareKey(key: IndexKey): IDBValidKey {
    if (Array.isArray(key)) {
      if (key.length == 1) {
        return val2Idb(key[0])
      } else {
        return key.map(val2Idb)
      }
    } else {
      return val2Idb(key)
    }
  }

  get(txn: IsarTxn, key: IDBValidKey): Promise<OBJ | undefined> {
    let store = txn.txn.objectStore(this.name)
    return new Promise((resolve, reject) => {
      let req = store.get(key)
      req.onsuccess = () => {
        const object = req.result ? this.toObject(req.result) : undefined
        resolve(object)
      }
      req.onerror = () => {
        reject(req.error)
      }
    })
  }

  getAllInternal(
    txn: IsarTxn,
    keys: IDBValidKey[],
    includeUndefined: boolean,
    indexName?: string,
  ): Promise<(OBJ | undefined)[]> {
    return new Promise((resolve, reject) => {
      const store = txn.txn.objectStore(this.name)
      const source = indexName ? store.index(indexName) : store
      const results: (OBJ | undefined)[] = []
      for (let i = 0; i < keys.length; i++) {
        let req = source.get(keys[i])
        req.onsuccess = () => {
          const result = req.result
          if (result) {
            results.push(this.toObject(result))
          } else if (includeUndefined) {
            results.push(undefined)
          }
          if (results.length == keys.length) {
            resolve(results)
          }
        }
        req.onerror = () => {
          reject(req.error)
        }
      }
    })
  }

  getAll(txn: IsarTxn, ids: number[]): Promise<(OBJ | undefined)[]> {
    return this.getAllInternal(txn, ids, true)
  }

  getAllByIndex(
    txn: IsarTxn,
    indexName: string,
    keys: IndexKey[],
  ): Promise<(OBJ | undefined)[]> {
    const idbKeys = keys.map(this.prepareKey)
    return this.getAllInternal(txn, idbKeys, true, indexName)
  }

  putAll(txn: IsarTxn, objects: OBJ[]): Promise<number[]> {
    let store = txn.txn.objectStore(this.name)
    return new Promise((resolve, reject) => {
      const ids: (number | undefined)[] = []
      const changeSet = txn.getChangeSet(this.name)
      for (let i = 0; i < objects.length; i++) {
        let object = obj2Idb(objects[i], this.idName)
        const req = store.put(object)
        const id = this.getId(object)
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
    return Promise.all([...linkPromises, ...backlinkPromises]).then(() => {})
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
    const idbKeys = keys.map(this.prepareKey)
    return bulkDeleteByIndex(txn, this.name, indexName, idbKeys).then(ids => {
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
