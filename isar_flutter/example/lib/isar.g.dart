import 'dart:ffi';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:isar/isar_native.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'user.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

export 'package:isar/isar.dart';

const utf8Encoder = Utf8Encoder();

final _isar = <String, Isar>{};

final _userCollection = <String, IsarCollection<User>>{};
Future<Isar> openIsar({String? directory}) async {
  final path = await _preparePath(directory);
  if (_isar[path] != null) {
    return _isar[path]!;
  }
  await Directory(path).create(recursive: true);
  initializeIsarCore();
  IC.isar_connect_dart_api(NativeApi.postCObject);
  final schemaPtr = IC.isar_schema_create();
  final collectionPtrPtr = allocate<Pointer>();
  {
    final namePtr = Utf8.toUtf8('User');
    nCall(IC.isar_schema_create_collection(collectionPtrPtr, namePtr.cast()));
    final collectionPtr = collectionPtrPtr.value;
    free(namePtr);
    {
      final pNamePtr = Utf8.toUtf8('age');
      nCall(IC.isar_schema_add_property(collectionPtr, pNamePtr.cast(), 3));
      free(pNamePtr);
    }
    {
      final pNamePtr = Utf8.toUtf8('name');
      nCall(IC.isar_schema_add_property(collectionPtr, pNamePtr.cast(), 5));
      free(pNamePtr);
    }
    {
      final propertiesPtrPtr = allocate<Pointer<Int8>>(count: 2);
      propertiesPtrPtr[0] = Utf8.toUtf8('name').cast();
      propertiesPtrPtr[1] = Utf8.toUtf8('age').cast();
      nCall(IC.isar_schema_add_index(
          collectionPtr, propertiesPtrPtr, 2, false, true));
      free(propertiesPtrPtr[0]);
      free(propertiesPtrPtr[1]);
      free(propertiesPtrPtr);
    }
    {
      final propertiesPtrPtr = allocate<Pointer<Int8>>(count: 1);
      propertiesPtrPtr[0] = Utf8.toUtf8('age').cast();
      nCall(IC.isar_schema_add_index(
          collectionPtr, propertiesPtrPtr, 1, false, false));
      free(propertiesPtrPtr[0]);
      free(propertiesPtrPtr);
    }
    nCall(IC.isar_schema_add_collection(schemaPtr, collectionPtrPtr.value));
  }

  final pathPtr = Utf8.toUtf8(path);
  final isarPtrPtr = allocate<Pointer>();
  final receivePort = ReceivePort();
  final nativePort = receivePort.sendPort.nativePort;
  IC.isar_create_instance(
      isarPtrPtr, pathPtr.cast(), 1000000000, schemaPtr, nativePort);
  await receivePort.first;
  free(pathPtr);

  final isarPtr = isarPtrPtr.value;
  final isar = IsarImpl(path, isarPtr);
  _isar[path] = isar;
  free(isarPtrPtr);
  nCall(IC.isar_get_collection(isarPtr, collectionPtrPtr, 0));
  _userCollection[path] =
      IsarCollectionImpl(isar, _UserAdapter(), collectionPtrPtr.value);
  free(collectionPtrPtr);
  return isar;
}

Future<String> _preparePath(String? path) async {
  if (path == null || p.isRelative(path)) {
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, path ?? 'isar');
  } else {
    return path;
  }
}

extension GetUserCollection on Isar {
  IsarCollection<User> get users {
    return _userCollection[path]!;
  }
}

class _UserAdapter extends TypeAdapter<User> {
  @override
  final staticSize = 18;

  @override
  int prepareSerialize(User object, Map<String, dynamic> cache) {
    var dynamicSize = 0;
    {
      final bytes = utf8Encoder.convert(object.name);
      cache['nameBytes'] = bytes;
      dynamicSize += bytes.length;
    }
    final size = dynamicSize + 18;
    return size + (-(size + 14) % 8);
  }

  @override
  void serialize(User object, Map<String, dynamic> cache, BinaryWriter writer) {
    writer.pad(2);
    writer.writeLong(object.age);
    writer.writeBytes(cache['nameBytes'] as Uint8List);
  }

  @override
  User deserialize(BinaryReader reader) {
    final object = User();
    reader.skip(2);
    object.age = reader.readLong();
    object.name = reader.readString();
    return object;
  }
}

extension UserQueryWhereSort on QueryBuilder<User, QNoWhere, dynamic, dynamic,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<
      User,
      dynamic,
      QCanFilter,
      QNoGroups,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> sortedByNameAge(/*[bool distinct = false]*/) {
    return addWhereClause(WhereClause(0, []));
  }

  QueryBuilder<
      User,
      dynamic,
      QCanFilter,
      QNoGroups,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> sortedByAge(/*[bool distinct = false]*/) {
    return addWhereClause(WhereClause(1, []));
  }
}

extension UserQueryWhere on QueryBuilder<User, QWhere, dynamic, dynamic,
    dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> nameEqualTo(String name) {
    return addWhereClause(WhereClause(
      0,
      ['String'],
      upper: [name],
      includeUpper: true,
      lower: [name],
      includeLower: true,
    ));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> nameNotEqualTo(String name) {
    final cloned = addWhereClause(WhereClause(
      0,
      ['String'],
      upper: [name],
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      0,
      ['String'],
      lower: [name],
      includeLower: false,
    ));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
          QCanOffsetLimit, QCanSort, QCanExecute>
      nameBetween(String lower, String upper,
          {bool includeLower = true, bool includeUpper = true}) {
    return addWhereClause(WhereClause(0, ['String'],
        upper: [upper],
        includeUpper: includeUpper,
        lower: [lower],
        includeLower: includeLower));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> nameAnyOf(List<String> values) {
    var q = this;
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.nameEqualTo(values[i]);
      } else {
        q = q.nameEqualTo(values[i]).or();
      }
    }
    throw UnimplementedError();
  }

  QueryBuilder<
      User,
      QWhereProperty,
      QCanFilter,
      QNoGroups,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> nameAgeEqualTo(String name, int age) {
    return addWhereClause(WhereClause(
      0,
      ['String', 'Long'],
      upper: [name, age],
      includeUpper: true,
      lower: [name, age],
      includeLower: true,
    ));
  }

  QueryBuilder<
      User,
      QWhereProperty,
      QCanFilter,
      QNoGroups,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> nameAgeNotEqualTo(String name, int age) {
    final cloned = addWhereClause(WhereClause(
      0,
      ['String', 'Long'],
      upper: [name, age],
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      0,
      ['String', 'Long'],
      lower: [name, age],
      includeLower: false,
    ));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> ageEqualTo(int age) {
    return addWhereClause(WhereClause(
      1,
      ['Long'],
      upper: [age],
      includeUpper: true,
      lower: [age],
      includeLower: true,
    ));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> ageNotEqualTo(int age) {
    final cloned = addWhereClause(WhereClause(
      1,
      ['Long'],
      upper: [age],
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      1,
      ['Long'],
      lower: [age],
      includeLower: false,
    ));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
          QCanOffsetLimit, QCanSort, QCanExecute>
      ageBetween(int lower, int upper,
          {bool includeLower = true, bool includeUpper = true}) {
    return addWhereClause(WhereClause(1, ['Long'],
        upper: [upper],
        includeUpper: includeUpper,
        lower: [lower],
        includeLower: includeLower));
  }

  QueryBuilder<User, QWhereProperty, QCanFilter, QNoGroups, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> ageAnyOf(List<int> values) {
    var q = this;
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.ageEqualTo(values[i]);
      } else {
        q = q.ageEqualTo(values[i]).or();
      }
    }
    throw UnimplementedError();
  }

  QueryBuilder<
      User,
      QWhereProperty,
      QCanFilter,
      QNoGroups,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> ageLowerThan(int value, {bool include = false}) {
    return addWhereClause(
        WhereClause(1, ['Long'], upper: [value], includeUpper: include));
  }

  QueryBuilder<
      User,
      QWhereProperty,
      QCanFilter,
      QNoGroups,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> ageGreaterThan(int value, {bool include = false}) {
    return addWhereClause(
        WhereClause(1, ['Long'], lower: [value], includeLower: include));
  }
}

extension UserQueryFilter<GROUPS> on QueryBuilder<User, dynamic, QFilter,
    GROUPS, dynamic, dynamic, dynamic, dynamic> {
  QueryBuilder<User, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> ageEqualTo(int value) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      0,
      'Long',
      value,
    ));
  }

  QueryBuilder<User, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> ageNotEqualTo(int value) {
    return addFilterCondition(QueryCondition(
      ConditionType.NEq,
      0,
      'Long',
      value,
    ));
  }

  QueryBuilder<
      User,
      dynamic,
      QFilterAfterCond,
      GROUPS,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> ageLowerThan(int value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Lt,
      0,
      'Long',
      value,
      includeValue: include,
    ));
  }

  QueryBuilder<
      User,
      dynamic,
      QFilterAfterCond,
      GROUPS,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> ageGreaterThan(int value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Gt,
      0,
      'Long',
      value,
      includeValue: include,
    ));
  }

  QueryBuilder<User, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy,
          QCanOffsetLimit, QCanSort, QCanExecute>
      ageBetween(int lower, int upper,
          {bool includeLower = true, bool includeUpper = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Between,
      0,
      'Long',
      lower,
      includeValue: includeLower,
      value2: upper,
      includeValue2: includeUpper,
    ));
  }

  QueryBuilder<User, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> nameEqualTo(String value) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      1,
      'String',
      value,
    ));
  }

  QueryBuilder<User, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy,
      QCanOffsetLimit, QCanSort, QCanExecute> nameNotEqualTo(String value) {
    return addFilterCondition(QueryCondition(
      ConditionType.NEq,
      1,
      'String',
      value,
    ));
  }

  QueryBuilder<
      User,
      dynamic,
      QFilterAfterCond,
      GROUPS,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> nameLowerThan(String value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Lt,
      1,
      'String',
      value,
      includeValue: include,
    ));
  }

  QueryBuilder<
      User,
      dynamic,
      QFilterAfterCond,
      GROUPS,
      QCanGroupBy,
      QCanOffsetLimit,
      QCanSort,
      QCanExecute> nameGreaterThan(String value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Gt,
      1,
      'String',
      value,
      includeValue: include,
    ));
  }

  QueryBuilder<User, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy,
          QCanOffsetLimit, QCanSort, QCanExecute>
      nameBetween(String lower, String upper,
          {bool includeLower = true, bool includeUpper = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Between,
      1,
      'String',
      lower,
      includeValue: includeLower,
      value2: upper,
      includeValue2: includeUpper,
    ));
  }
}
