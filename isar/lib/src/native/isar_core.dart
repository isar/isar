part of isar_native;

const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minFloat = -3.40282347e+38;
const maxFloat = 3.40282347e+38;
const minDouble = -1.7976931348623157e+308;
const maxDouble = 1.7976931348623157e+308;

const nullInt = minInt;
const nullLong = minLong;
const nullBool = 0;
const trueBool = 1;
const falseBool = 2;

class IsarCoreUtils {
  static final syncTxnPtr = allocate<Pointer>();
  static final syncRawObjPtr = allocate<RawObject>();
}

late IsarCoreBindings IsarCore;

extension RawObjectX on RawObject {
  ObjectId? get oid {
    if (oid_time != 0) {
      return ObjectIdImpl(oid_time, oid_rand_counter);
    } else {
      return null;
    }
  }

  set oid(ObjectId? oid) {
    if (oid != null) {
      final oidImpl = oid as ObjectIdImpl;
      oid_time = oidImpl.time;
      oid_rand_counter = oidImpl.randCounter;
    } else {
      oid_time = 0;
      oid_rand_counter = 0;
    }
  }
}
