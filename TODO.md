<h1 align="center"> Roadmap and TODOs</p>


# Documentation

## API Docs

- [ ] Document all public APIs

## Schema

- [x] Update schema migration instructions
- [ ] Document all annotation options

## CRUD

- [ ] Document sync operations
- [x] `getAll()`, `putAll`, `deleteAll()`
- [ ] `getBy...()`, `deleteBy...()`

## Queries

- [x] Filter groups
- [x] Boolean operators `and()`, `or()`, `not()`
- [x] Offset, limit
- [x] Distinct where clauses
- [x] Different filter operations (`equalTo`, `beginsWith()` etc.)
- [ ] Better explanation for distinct and sorted where clauses
- [ ] Watching queries

## Indexes

- [ ] Intro
- [x] What are they
- [ ] Why use them
- [x] How to in isar?

## Examples

- [ ] Create minimal example
- [ ] Create complex example with indexes, filter groups etc.
- [ ] More Sample Apps

## Tutorials

- [ ] How to write fast queries
- [ ] Build a simple offline first app
- [ ] Advanced queries


----


# Isar Dart

## Features

- [x] Distinct by
- [x] Offset, Limit
- [x] Sorted by

## Fixes

- [x] Provide an option to change collection accessor names

## Unit tests

- [x] Download binaries automatically for tests

### Queries

- [x] Restructure query tests to make them less verbose
- [x] Define models that can be reused across tests
- [x] Where clauses with string indexes (value, hash, words, case-sensitive)
- [x] Distinct where clauses
- [x] String filter operations


----


# Isar Core

## Features (low priority)

- [ ] Draft Synchronization
- [x] Relationships

## Unit tests

- [ ] Make mdbx unit tests bulletproof
- [x] Migration tests
- [x] Binary format
- [x] CRUD
- [x] Links
- [ ] QueryBuilder
- [ ] WhereClause
- [ ] WhereExecutor
- [x] CollectionMigrator
- [ ] Watchers


----


# Isar Web

- [ ] MVP


