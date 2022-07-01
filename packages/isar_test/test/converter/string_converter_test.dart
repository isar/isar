import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'string_converter_test.g.dart';

@Collection()
class StringModel {
  StringModel({
    required this.authProvider,
    required this.number,
    required this.nullableNumber,
  });

  final id = Isar.autoIncrement;

  @AuthProvidersTypeConverter()
  final AuthProviders authProvider;

  @NumStringifierTypeConverter()
  @Index()
  final num number;

  @NullableNumStringifierTypeConverter()
  final num? nullableNumber;

  @override
  String toString() {
    return 'StringModel{id: $id, authProvider: $authProvider, number: $number, nullableNumber: $nullableNumber}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          authProvider == other.authProvider &&
          number == other.number &&
          nullableNumber == other.nullableNumber;

  @override
  int get hashCode =>
      id.hashCode ^
      authProvider.hashCode ^
      number.hashCode ^
      nullableNumber.hashCode;
}

enum AuthProviders {
  password('password'),
  google('google.com'),
  facebook('facebook.com'),
  apple('apple.com'),
  github('github.com'),
  none(null);

  const AuthProviders(this.value);

  final String? value;
}

class AuthProvidersTypeConverter extends TypeConverter<AuthProviders, String?> {
  const AuthProvidersTypeConverter();

  @override
  AuthProviders fromIsar(String? value) {
    return AuthProviders.values.firstWhere(
      (provider) => provider.value == value,
    );
  }

  @override
  String? toIsar(AuthProviders provider) => provider.value;
}

class NumStringifierTypeConverter extends TypeConverter<num, String> {
  const NumStringifierTypeConverter();

  @override
  num fromIsar(String value) => num.parse(value);

  @override
  String toIsar(num value) => value.toString();
}

class NullableNumStringifierTypeConverter extends TypeConverter<num?, String?> {
  const NullableNumStringifierTypeConverter();

  @override
  num? fromIsar(String? value) {
    if (value == null) return null;
    return num.parse(value);
  }

  @override
  String? toIsar(num? value) => value?.toString();
}

void main() {
  group('String converter', () {
    late Isar isar;

    late StringModel obj0;
    late StringModel obj1;
    late StringModel obj2;
    late StringModel obj3;
    late StringModel obj4;
    late StringModel obj5;

    setUp(() async {
      isar = await openTempIsar([StringModelSchema]);

      obj0 = StringModel(
        authProvider: AuthProviders.github,
        number: 1,
        nullableNumber: null,
      );
      obj1 = StringModel(
        authProvider: AuthProviders.facebook,
        number: 42.12,
        nullableNumber: 123,
      );
      obj2 = StringModel(
        authProvider: AuthProviders.none,
        number: 0,
        nullableNumber: null,
      );
      obj3 = StringModel(
        authProvider: AuthProviders.password,
        number: 1024,
        nullableNumber: null,
      );
      obj4 = StringModel(
        authProvider: AuthProviders.apple,
        number: 0.5,
        nullableNumber: 92,
      );
      obj5 = StringModel(
        authProvider: AuthProviders.github,
        number: -2048,
        nullableNumber: 42.42,
      );

      await isar.tWriteTxn(
        () => isar.stringModels.tPutAll([obj0, obj1, obj2, obj3, obj4, obj5]),
      );
    });

    tearDown(() => isar.close());

    // FIXME: This seems to be an issue with the generator, that generates
    // methods which don't support nullable string as argument
    //
    // test/converter/string_converter_test.g.dart:608:64:
    // Error: The argument type 'String?' can't be assigned to the parameter
    // type 'String' because 'String?' is nullable and 'String' isn't.
    //
    isarTest('Query by authProvider', () async {
      await qEqual(
        isar.stringModels
            .filter()
            .authProviderEqualTo(AuthProviders.github)
            .tFindAll(),
        [obj0, obj5],
      );
    });

    isarTest('Query by number index', () async {
      await qEqual(
        isar.stringModels
            .where()
            .numberEqualTo(1)
            .or()
            .numberEqualTo(-2048)
            .tFindAll(),
        [obj0, obj5],
      );
    });

    // TODO(jtplouffe): implement more tests once the generator issues are fixed
  });
}
