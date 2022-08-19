---
title: FAQ
---

# Frequently Asked Questions

A random collection of frequently asked questions about Isar and Flutter databases.

### Why do I need a database?

> I store my data in a backend database, why do I need Isar?.

Even today, it is very common to have no data connection, if you are in a subway or in a plane, or if you visit your grandma who has no WiFi and very bad cell signal. You shouldn't let bad signal cripple your app!

### Isar vs Hive

The answer to this one is easy: do you have structured data or do you want to query your data? Use Isar. For dynamic data or very simple use cases, you can use Hive.

### Benchmarks

> I saw this one benchmark where database X was faster than Isar.

Database performance is very dependent on the use case. Most benchmarks just dump 10000 records into the database and then read them back. That will almost never happen in real life.  
Isar is extremely fast and has a few unique tricks to allow you to write much faster queries than with databases that look faster in benchmarks (like composite and multi-entry indexes, FTS etc.).

Some databases don't even support asynchronous access and require you to either run all operations in a separate isolate or block your UI isolate.

### Where clauses?!

> Why do **_I_** have to choose which index to use?

There are multiple reasons. Many databases use heuristics to choose the best index for a given query. The database needs to collect additional usage data (-> overhead) might still choose the wrong index. It also makes creating a query slower.

Nobody knows your data better than you, the developer. So you can choose the optimal index and decide for example whether you want to use an index for querying or sorting.

### Do I have to use indexes / where clauses?

Nope! Isar is often fast enough if you only rely on filters.

### Does Isar increase the size of my app?

A little bit, yes. Isar will increase the download size of your app about 1 - 1.5 MB. Isar Web only a few KB.

### The docs are incorrect / there is a typo.

Oh no, sorry. Please [open an issue](https://github.com/isar/isar/issues/new/choose) or even better a [PR](https://github.com/isar/docs) to fix it 💪.
