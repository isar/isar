import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:isar/src/native/bindings/structs.dart';

// ISAR

typedef NICreateInstance = Uint8 Function(
  Pointer<Pointer> isarPtr,
  Pointer<Utf8> path,
  Uint32 maxDbSize,
  Pointer<Utf8> schema,
);
typedef ICreateInstance = int Function(
  Pointer<Pointer> isarPtr,
  Pointer<Utf8> path,
  int maxDbSize,
  Pointer<Utf8> schema,
);

typedef NIGetCollection = Uint8 Function(
  Pointer isar,
  Pointer<Pointer> collectionPtr,
  Uint32 collectionIndex,
);
typedef IGetCollection = int Function(
  Pointer isar,
  Pointer<Pointer> collectionPtr,
  int collectionIndex,
);

//TXN

typedef NITxnBegin = Uint8 Function(
  Pointer isar,
  Pointer<Pointer> txnPtr,
  Uint8 isWrite,
);
typedef ITxnBegin = int Function(
  Pointer isar,
  Pointer<Pointer> txnPtr,
  int isWrite,
);

typedef NITxnCommit = Uint8 Function(
  Pointer txn,
);
typedef ITxnCommit = int Function(
  Pointer txn,
);

typedef NITxnAbort = Uint8 Function(
  Pointer txn,
);
typedef ITxnAbort = int Function(
  Pointer txn,
);

//CRUD

typedef NIGet = Uint8 Function(
  Pointer collection,
  Pointer txn,
  Pointer<RawObject> objectId,
);
typedef IGet = int Function(
  Pointer collection,
  Pointer txn,
  Pointer<RawObject> objectId,
);

typedef NIPut = Uint8 Function(
  Pointer collection,
  Pointer txn,
  Pointer<RawObject> obj,
);
typedef IPut = int Function(
  Pointer collection,
  Pointer txn,
  Pointer<RawObject> obj,
);

typedef NIDelete = Uint8 Function(
  Pointer collection,
  Pointer txn,
  Pointer<RawObject> objectId,
);
typedef IDelete = int Function(
  Pointer collection,
  Pointer txn,
  Pointer<RawObject> objectId,
);

// QUERY
typedef NCreateWC = Pointer Function(
  Pointer collection,
  Uint32 index,
  Uint32 upperKeySize,
  Uint32 lowerKeySize,
);
typedef ICreateWC = Pointer Function(
  Pointer collection,
  int index,
  int upperKeySize,
  int lowerKeySize,
);

typedef NWCAddInt = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Int64 value,
  Uint8 include,
);
typedef IWCAddInt = void Function(
  Pointer whereClause,
  int lower,
  int value,
  int include,
);

typedef NWCAddDouble = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Double value,
  Uint8 include,
);
typedef IWCAddDouble = void Function(
  Pointer whereClause,
  int lower,
  double value,
  int include,
);

typedef NWCAddBool = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Uint8 value,
);
typedef IWCAddBool = void Function(
  Pointer whereClause,
  int lower,
  int value,
);

typedef NWCAddStringHash = Void Function(
  Pointer whereClause,
  Pointer<Uint8> value,
);
typedef IWCAddStringHash = void Function(
  Pointer whereClause,
  Pointer<Uint8> value,
);

typedef NWCAddStringValue = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Pointer<Uint8> value,
  Uint8 include,
);
typedef IWCAddStringValue = void Function(
  Pointer whereClause,
  int lower,
  Pointer<Uint8> value,
  int include,
);
