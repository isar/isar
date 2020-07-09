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

typedef NIGetBank = Uint8 Function(
  Pointer isar,
  Pointer<Pointer> bankPtr,
  Uint32 bankIndex,
);
typedef IGetBank = int Function(
  Pointer isar,
  Pointer<Pointer> bankPtr,
  int bankIndex,
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
  Pointer bank,
  Pointer txn,
  Pointer<RawObject> objectId,
);
typedef IGet = int Function(
  Pointer bank,
  Pointer txn,
  Pointer<RawObject> objectId,
);

typedef NIPut = Uint8 Function(
  Pointer bank,
  Pointer txn,
  Pointer<RawObject> obj,
);
typedef IPut = int Function(
  Pointer bank,
  Pointer txn,
  Pointer<RawObject> obj,
);

typedef NIDelete = Uint8 Function(
  Pointer bank,
  Pointer txn,
  Pointer<RawObject> objectId,
);
typedef IDelete = int Function(
  Pointer bank,
  Pointer txn,
  Pointer<RawObject> objectId,
);

// QUERY
typedef NCreateWC = Pointer Function(
  Pointer bank,
  Uint32 index,
  Uint32 upperKeySize,
  Uint32 lowerKeySize,
);
typedef ICreateWC = Pointer Function(
  Pointer bank,
  int index,
  int upperKeySize,
  int lowerKeySize,
);

typedef NWCAddInt = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Int64 value,
);
typedef IWCAddInt = void Function(
  Pointer whereClause,
  int lower,
  int value,
);

typedef NWCAddDouble = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Double value,
);
typedef IWCAddDouble = void Function(
  Pointer whereClause,
  int lower,
  double value,
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
  Uint8 lower,
  Pointer<Uint8> value,
);
typedef IWCAddStringHash = void Function(
  Pointer whereClause,
  int lower,
  Pointer<Uint8> value,
);

typedef NWCAddStringValue = Void Function(
  Pointer whereClause,
  Uint8 lower,
  Pointer<Uint8> value,
);
typedef IWCAddStringValue = void Function(
  Pointer whereClause,
  int lower,
  Pointer<Uint8> value,
);
