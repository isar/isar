<h1 align="center"> Roadmap and TODOs</p>


# Documentation

## Schema

- [ ] Update schema migration instructions

## CRUD

- [ ] Document sync operations
- [ ] `getAll()`, `putAll`, `deleteAll()`

## Queries

- [ ] Filter groups
- [ ] Boolean operators `and()`, `or()`, `not()`
- [ ] Offset, limit
- [ ] Distinct where clauses
- [ ] Different filter operations (`equalTo`, `beginsWith()` etc.)

## Indexes

- [ ] Intro
- [ ] What are they
- [ ] Why use them
- [ ] How to in isar?

## Examples

- [ ] Create minimal example
- [ ] Create complex example with indexes, filter groups etc.

## Tutorials

- [ ] How to write fast queries


----


# Isar Dart

## Features

- [ ] Distinct by
- [ ] Offset, Limit
- [ ] Sorted by

## Fixes

- [ ] Port [pluralize](https://github.com/plurals/pluralize) to Dart and use it to generate collection accessors

## Unit tests

- [ ] Download binaries automatically for tests

### Queries

- [ ] Restructure query tests to make them less verbose
- [ ] Define models that can be reused across tests
- [ ] Where clauses with string indexes (value, hash, words, case-sensitive)
- [ ] Distinct where clauses
- [ ] String filter operations


----


# Isar Core

## Features (low priority)

- [ ] Draft Synchronization
- [ ] Relationships

## Unit tests

- [ ] Make lmdb unit tests bulletproof
- [ ] Migration tests
- [ ] QueryBuilder
- [ ] WhereClause
- [ ] WhereExecutor
- [ ] CollectionMigrator
- [ ] Watchers


