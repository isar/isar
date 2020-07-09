import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/src/native/bindings/signatures.dart';
import 'package:isar/src/native/bindings/structs.dart';

final isarBindings = IsarBindings();

class IsarBindings {
  static final ptr = allocate<Pointer>();

  static final obj = allocate<RawObject>();

  ICreateInstance createInstance;
  IGetBank getBank;

  ITxnBegin beginTxn;
  ITxnCommit commitTxn;
  ITxnAbort abortTxn;

  IGet getObject;
  IPut putObject;
  IPut putObjects;
  IDelete deleteObject;

  ICreateWC createWc;
  IWCAddInt wcAddInt;
  IWCAddDouble wcAddDouble;
  IWCAddBool wcAddBool;
  IWCAddStringHash wcAddStringHash;
  IWCAddStringValue wcAddStringValue;

  int Function() isar_test;

  IsarBindings() {
    final dylib = DynamicLibrary.open(
        "/home/simon/Desktop/isar/target/debug/libisar_core.so");

    Pointer<NativeFunction<T>> lookup<T extends Function>(String symbolName) {
      return dylib.lookup<NativeFunction<T>>("isar_" + symbolName);
    }

    createInstance = lookup<NICreateInstance>("create_instance").asFunction();
    getBank = lookup<NIGetBank>("get_bank").asFunction();

    beginTxn = lookup<NITxnBegin>("txn_begin").asFunction();
    commitTxn = lookup<NITxnCommit>("txn_commit").asFunction();
    abortTxn = lookup<NITxnAbort>("txn_abort").asFunction();

    getObject = lookup<NIGet>("get").asFunction();
    putObject = lookup<NIPut>("put").asFunction();
    deleteObject = lookup<NIDelete>("delete").asFunction();

    createWc = lookup<NCreateWC>("wc_create").asFunction();
    wcAddInt = lookup<NWCAddInt>("wc_add_int").asFunction();
    wcAddDouble = lookup<NWCAddDouble>("wc_add_double").asFunction();
    wcAddBool = lookup<NWCAddBool>("wc_add_bool").asFunction();
    wcAddStringHash =
        lookup<NWCAddStringHash>("wc_add_string_hash").asFunction();
    wcAddStringValue =
        lookup<NWCAddStringValue>("wc_add_string_value").asFunction();
  }
}
