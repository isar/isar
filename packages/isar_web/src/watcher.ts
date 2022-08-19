import { IsarQuery } from './query'
import { IsarTxn } from './txn'

type ChangeCallback = () => void

type ObjectChangeCallback<OBJ> = (object?: OBJ) => void

type QueryChangeCallback<OBJ> = (results: OBJ[]) => void

type StopWatching = () => void

type QueryWatcher<OBJ> = {
  callback: ChangeCallback | QueryChangeCallback<OBJ>
  query: IsarQuery<OBJ>
  lazy: boolean
}

export type ChangeSet<OBJ> = {
  cleared: boolean
  addedObjects: Map<number, OBJ>
  deletedObjectIds: Set<number>
}

export class IsarChangeSet<OBJ> implements IsarChangeSet<OBJ> {
  cleared: boolean = false
  addedObjects: Map<number, OBJ> = new Map()
  deletedObjectIds: Set<number> = new Set()

  registerChange(id: number, idbObject?: OBJ) {
    if (idbObject) {
      this.addedObjects.set(id, idbObject)
      this.deletedObjectIds.delete(id)
    } else {
      this.deletedObjectIds.add(id)
      this.addedObjects.delete(id)
    }
  }

  registerCleared() {
    this.addedObjects.clear()
    this.deletedObjectIds.clear()
    this.cleared = true
  }
}

export class IsarWatchable<OBJ> {
  readonly collectionWatchers = new Set<ChangeCallback>()
  readonly objectWatchers: Map<number, Set<ObjectChangeCallback<OBJ>>> =
    new Map()
  readonly queryWatchers = new Set<QueryWatcher<OBJ>>()

  watchLazy(callback: ChangeCallback): StopWatching {
    this.collectionWatchers.add(callback)
    return () => this.collectionWatchers.delete(callback)
  }

  watchObject(id: number, callback: ObjectChangeCallback<OBJ>): StopWatching {
    let ow = this.objectWatchers.get(id)
    if (ow == null) {
      ow = new Set()
      this.objectWatchers.set(id, ow)
    }
    ow.add(callback)
    return () => {
      if (ow!.size <= 1) {
        this.objectWatchers.delete(id)
      } else {
        ow!.delete(callback)
      }
    }
  }

  private watchQueryInternal(
    query: IsarQuery<OBJ>,
    lazy: boolean,
    callback: ChangeCallback | QueryChangeCallback<OBJ>,
  ): StopWatching {
    const watcher = { callback, query, lazy }
    this.queryWatchers.add(watcher)
    return () => this.queryWatchers.delete(watcher)
  }

  watchQuery(
    query: IsarQuery<OBJ>,
    callback: QueryChangeCallback<OBJ>,
  ): StopWatching {
    return this.watchQueryInternal(query, false, callback)
  }

  watchQueryLazy(
    query: IsarQuery<OBJ>,
    callback: ChangeCallback,
  ): StopWatching {
    return this.watchQueryInternal(query, true, callback)
  }

  notify(changes: ChangeSet<OBJ>, getTxn: () => IsarTxn) {
    if (
      !changes.cleared &&
      changes.addedObjects.size === 0 &&
      changes.deletedObjectIds.size === 0
    ) {
      return
    }

    function notifyQuery(watcher: QueryWatcher<OBJ>) {
      if (watcher.lazy) {
        ;(watcher.callback as ChangeCallback)()
      } else {
        const txn = getTxn()
        watcher.query.findAll(txn).then(watcher.callback)
      }
    }

    for (const watcher of this.collectionWatchers) {
      watcher()
    }

    let queryWatchers: Set<QueryWatcher<OBJ>> | undefined
    if (changes.cleared || changes.deletedObjectIds.size > 0) {
      for (const watcher of this.queryWatchers) {
        notifyQuery(watcher)
      }
    } else {
      queryWatchers = new Set(this.queryWatchers)
    }

    if (changes.cleared) {
      for (const [id, callbacks] of this.objectWatchers) {
        for (let callback of callbacks) {
          callback(changes.addedObjects.get(id))
        }
      }
    } else {
      for (const id of changes.deletedObjectIds) {
        const callbacks = this.objectWatchers.get(id)
        if (callbacks != null) {
          for (let callback of callbacks) {
            callback(undefined)
          }
        }
      }

      for (const [id, added] of changes.addedObjects) {
        const ow = this.objectWatchers.get(id)
        if (ow != null) {
          for (let callback of ow) {
            callback(added)
          }
        }

        if (queryWatchers != null) {
          for (const watcher of queryWatchers) {
            if (watcher.query.whereClauseAndFilterMatch(id, added)) {
              notifyQuery(watcher)
              queryWatchers.delete(watcher)
            }
          }
        }
      }
    }
  }
}
