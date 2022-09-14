import { IsarCollection } from './collection'
import { useCursor } from './cursor'
import { idName } from './instance'
import { IsarLink } from './link'
import { IsarTxn } from './txn'

type IdWherClause = {
  range?: IDBKeyRange
}

type IndexWherClause = {
  indexName: string
  range?: IDBKeyRange
}

type LinkWherClause = {
  linkCollection: string
  linkName: string
  backlink: boolean
  id: number
}

type WherClause = IdWherClause | IndexWherClause | LinkWherClause

type Filter = (id: number, obj: any) => boolean

type Cmp = (a: any, b: any) => number

type DistinctValue = (obj: any) => string

export class IsarQuery<OBJ> {
  collection: IsarCollection<OBJ>
  whereClauses: WherClause[]
  whereClauseDirection: IDBCursorDirection
  filter?: Filter
  sortCmp?: Cmp
  distinctValue?: DistinctValue
  offset: number
  limit: number

  constructor(
    collection: IsarCollection<OBJ>,
    whereClauses: WherClause[],
    whereDistinct: boolean,
    whereAscending: boolean,
    filter?: Filter,
    sortCmp?: Cmp,
    distinctValue?: DistinctValue,
    offset?: number,
    limit?: number,
  ) {
    this.collection = collection
    this.whereClauses = whereClauses
    this.filter = filter
    this.sortCmp = sortCmp
    this.distinctValue = distinctValue
    this.offset = offset ?? 0
    this.limit = limit ?? Infinity

    if (whereDistinct) {
      this.whereClauseDirection = whereAscending ? 'nextunique' : 'prevunique'
    } else {
      this.whereClauseDirection = whereAscending ? 'next' : 'prev'
    }

    if (this.whereClauses.length === 0) {
      this.whereClauses.push({})
    }
  }

  private getWhereClauseRange(
    whereClause: IdWherClause | IndexWherClause,
  ): IDBKeyRange {
    return whereClause.range ?? IDBKeyRange.lowerBound(-Infinity)
  }

  private async findInternal(txn: IsarTxn, limit: number): Promise<any[]> {
    const offset = this.offset
    const unsortedLimit = !this.sortCmp ? offset + limit : Infinity
    const unsortedDistinct = !this.sortCmp ? this.distinctValue : undefined
    let results: OBJ[] = []
    const idsSet = new Set<number>()
    const distinctSet = new Set<String>()

    const cursorCallback = (
      id: any,
      object: any,
      next: Function,
      resolve: Function,
    ) => {
      if (idsSet.has(id)) {
        next()
        return
      } else {
        idsSet.add(id)
      }

      if (this.filter) {
        if (!this.filter(id, object)) {
          next()
          return
        }
      }
      if (unsortedDistinct) {
        const value = unsortedDistinct(object)
        if (distinctSet.has(value)) {
          next()
          return
        } else {
          distinctSet.add(value)
        }
      }
      object[idName] = id
      results.push(object)
      if (results.length < unsortedLimit) {
        next()
      } else {
        resolve()
      }
    }

    for (const whereClause of this.whereClauses) {
      if (results.length >= unsortedLimit) {
        break
      }
      if ('linkName' in whereClause) {
        const link = this.collection.isar
          .getCollection(whereClause.linkCollection)
          .getLink(whereClause.linkName)!
        await useCursor({
          txn,
          storeName: link.storeName,
          indexName: whereClause.backlink ? IsarLink.BacklinkIndex : undefined,
          range: IsarLink.getLinkKeyRange(whereClause.id),
          direction: this.whereClauseDirection,
          callback: (key, _, next, resolve, reject) => {
            const id = (key as number[])[whereClause.backlink ? 0 : 1]
            this.collection
              .get(txn, id)
              .then(obj => {
                if (obj) {
                  cursorCallback(id, obj, next, resolve)
                } else {
                  next()
                }
              })
              .catch(() => reject())
          },
        })
      } else {
        const range = this.getWhereClauseRange(whereClause)
        await useCursor({
          txn,
          storeName: this.collection.name,
          indexName:
            'indexName' in whereClause ? whereClause.indexName : undefined,
          range: range,
          direction: this.whereClauseDirection,
          callback: cursorCallback,
        })
      }
    }

    if (this.sortCmp) {
      results.sort(this.sortCmp)

      const distinctValue = this.distinctValue
      if (distinctValue) {
        results = results.filter(obj => {
          const value = distinctValue!(obj)
          if (!distinctSet.has(value)) {
            distinctSet.add(value)
            return true
          } else {
            return false
          }
        })
      }
    }

    return results.slice(offset, offset + limit)
  }

  findFirst(txn: IsarTxn): Promise<OBJ | undefined> {
    return this.findInternal(txn, 1).then(results => {
      return results.length > 0 ? results[0] : undefined
    })
  }

  findAll(txn: IsarTxn): Promise<OBJ[]> {
    return this.findInternal(txn, this.limit ?? Infinity)
  }

  deleteFirst(txn: IsarTxn): Promise<boolean> {
    return this.findInternal(txn, 1).then(result => {
      if (result.length !== 0) {
        return this.collection
          .deleteAll(txn, [result[0][idName]])
          .then(() => true)
      } else {
        return false
      }
    })
  }

  deleteAll(txn: IsarTxn): Promise<number> {
    return this.findInternal(txn, this.limit).then(result => {
      return this.collection
        .deleteAll(txn, result.map(obj => obj[idName]))
        .then(() => result.length)
    })
  }

  min(txn: IsarTxn, key: string): Promise<number | undefined> {
    return this.findAll(txn).then(results => {
      let min: number | undefined = undefined
      for (const obj of results) {
        const value = (obj as any)[key]
        if (value != null && (min == null || value < min)) {
          min = value
        }
      }
      return min
    })
  }

  max(txn: IsarTxn, key: string): Promise<number | undefined> {
    return this.findAll(txn).then(results => {
      let max: number | undefined = undefined
      for (const obj of results) {
        const value = (obj as any)[key]
        if (value != null && (max == null || value > max)) {
          max = value
        }
      }
      return max
    })
  }

  sum(txn: IsarTxn, key: string): Promise<number> {
    return this.findAll(txn).then(results => {
      let sum = 0
      for (const obj of results) {
        const value = (obj as any)[key]
        if (value != null) {
          sum += value
        }
      }
      return sum
    })
  }

  average(txn: IsarTxn, key: string): Promise<number> {
    return this.findAll(txn).then(results => {
      let sum = 0
      let count = 0
      for (const obj of results) {
        const value = (obj as any)[key]
        if (value != null) {
          sum += value
          count++
        }
      }
      return sum / count
    })
  }

  count(txn: IsarTxn): Promise<number> {
    return this.findAll(txn).then(result => result.length)
  }

  private whereClauseMatches(id: number, object: OBJ) {
    for (const whereClause of this.whereClauses) {
      if ('linkName' in whereClause) {
        return true
      } else if ('indexName' in whereClause) {
        if (this.collection.isMultiEntryIndex(whereClause.indexName)) {
          const values = (object as any)[
            this.collection.getIndexKeyPath(whereClause.indexName!)[0]
          ]
          for (let value of values) {
            if (this.getWhereClauseRange(whereClause).includes(value)) {
              return true
            }
          }
        } else {
          let value = this.collection
            .getIndexKeyPath(whereClause.indexName!)
            .map(p =>
              p === this.collection.idName ? id : (object as any)[p],
            )
          if (value.length === 1) {
            value = value[0]
          }
          if (this.getWhereClauseRange(whereClause).includes(value)) {
            return true
          }
        }
      } else if (this.getWhereClauseRange(whereClause).includes(id)) {
        return true
      }
    }

    return false
  }

  whereClauseAndFilterMatch(id: number, idbObject: OBJ): boolean {
    if (!this.whereClauseMatches(id, idbObject)) {
      return false
    }

    if (this.filter) {
      if (!this.filter(id, idbObject)) {
        return false
      }
    }

    return true
  }
}
