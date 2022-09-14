import equal from 'fast-deep-equal'

export type Schema = {
  name: string
  properties: Array<PropertySchema>
  indexes: Array<IndexSchema>
  links: Array<LinkSchema>
}

type PropertySchema = {
  name: string
  type: IsarType
}

type IndexSchema = {
  name: string
  unique: boolean
  properties: Array<IndexPropertySchema>
}

type IndexPropertySchema = {
  name: string
  type: IndexType
  caseSensitive: boolean
}

export namespace IndexSchema {
  export function isIndexMultiEntry(
    schema: Schema,
    indexSchema: IndexSchema,
  ): boolean {
    return indexSchema.properties.some(ip => {
      const property = schema.properties.find(p => p.name === ip.name)!
      return ip.type === IndexType.Value && IsarType.isList(property.type)
    })
  }

  export function getKeyPath(indexSchema: IndexSchema): string | string[] {
    return indexSchema.properties.length === 1
      ? indexSchema.properties[0].name
      : indexSchema.properties.map(p => p.name)
  }

  export function matchesIndex(
    schema: Schema,
    indexSchema: IndexSchema,
    index: IDBIndex,
  ): boolean {
    return (
      index.name === indexSchema.name &&
      index.multiEntry === isIndexMultiEntry(schema, indexSchema) &&
      index.unique === indexSchema.unique &&
      equal(index.keyPath, getKeyPath(indexSchema))
    )
  }
}

type LinkSchema = {
  name: string
  target: string
}

export namespace LinkSchema {
  export function getStoreName(
    sourceName: string,
    targetName: string,
    linkName: string,
  ): string {
    return `_${sourceName}_${targetName}_${linkName}`
  }
}

export enum IsarType {
  Bool = 'Bool',
  Byte = 'Byte',
  Int = 'Int',
  Float = 'Float',
  Long = 'Long',
  Double = 'Double',
  DateTime = 'DateTime',
  String = 'String',
  Object = 'Object',
  BoolList = 'BoolList',
  ByteList = 'ByteList',
  IntList = 'IntList',
  FloatList = 'FloatList',
  LongList = 'LongList',
  DoubleList = 'DoubleList',
  DateTimeList = 'DateTimeList',
  StringList = 'StringList',
  ObjectList = 'ObjectList',
}

export namespace IsarType {
  export function isList(type: IsarType): boolean {
    return type.endsWith('List')
  }
}

enum IndexType {
  Value = 'Value',
  Hash = 'Hash',
  HashElements = 'HashElements',
}
