import { idName } from "./instance"

export function val2Idb(value: any): any {
  if (value == null || value != value) {
    return -Infinity
  } else if (value === true) {
    return 1
  } else if (value === false) {
    return 0
  } else {
    return value
  }
}

export function obj2Idb(object: any): any {
  const result: any = Object.create(null, {})
  for (let key of Object.keys(object)) {
    const val = object[key]
    if (Array.isArray(val)) {
      result[key] = val.map(val2Idb)
    } else if (key !== idName || (val != null && val !== -Infinity)) {
      result[key] = val2Idb(val)
    }
  }
  return result
}

export function idb2Obj(id: number, object: any, boolValues: string[]): any {
  const result: any = {}
  for (let key of Object.keys(object)) {
    const val = object[key]
    if (val === -Infinity) {
      result[key] = null
    } else if (boolValues.indexOf(key) !== -1) {
      if (Array.isArray(val)) {
        result[key] = val.map(v => (v === -Infinity ? null : v > 0))
      } else {
        result[key] = val === 1
      }
    } else if (Array.isArray(val)) {
      result[key] = val.map(v => (v === -Infinity ? null : v))
    } else {
      result[key] = val
    }
  }
  return result
}

// Polyfill for older browsers

if (typeof IDBTransaction.prototype.commit !== "function") {
  IDBTransaction.prototype.commit = function () { }
}