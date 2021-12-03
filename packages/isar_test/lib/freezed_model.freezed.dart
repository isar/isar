// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'freezed_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$FreezedModelTearOff {
  const _$FreezedModelTearOff();

  MyFreezedModel call({int? id, required String name}) {
    return MyFreezedModel(
      id: id,
      name: name,
    );
  }
}

/// @nodoc
const $FreezedModel = _$FreezedModelTearOff();

/// @nodoc
mixin _$FreezedModel {
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FreezedModelCopyWith<FreezedModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FreezedModelCopyWith<$Res> {
  factory $FreezedModelCopyWith(
          FreezedModel value, $Res Function(FreezedModel) then) =
      _$FreezedModelCopyWithImpl<$Res>;
  $Res call({int? id, String name});
}

/// @nodoc
class _$FreezedModelCopyWithImpl<$Res> implements $FreezedModelCopyWith<$Res> {
  _$FreezedModelCopyWithImpl(this._value, this._then);

  final FreezedModel _value;
  // ignore: unused_field
  final $Res Function(FreezedModel) _then;

  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
abstract class $MyFreezedModelCopyWith<$Res>
    implements $FreezedModelCopyWith<$Res> {
  factory $MyFreezedModelCopyWith(
          MyFreezedModel value, $Res Function(MyFreezedModel) then) =
      _$MyFreezedModelCopyWithImpl<$Res>;
  @override
  $Res call({int? id, String name});
}

/// @nodoc
class _$MyFreezedModelCopyWithImpl<$Res>
    extends _$FreezedModelCopyWithImpl<$Res>
    implements $MyFreezedModelCopyWith<$Res> {
  _$MyFreezedModelCopyWithImpl(
      MyFreezedModel _value, $Res Function(MyFreezedModel) _then)
      : super(_value, (v) => _then(v as MyFreezedModel));

  @override
  MyFreezedModel get _value => super._value as MyFreezedModel;

  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
  }) {
    return _then(MyFreezedModel(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MyFreezedModel implements MyFreezedModel {
  const _$MyFreezedModel({this.id, required this.name});

  @override
  final int? id;
  @override
  final String name;

  @override
  String toString() {
    return 'FreezedModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is MyFreezedModel &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(name);

  @JsonKey(ignore: true)
  @override
  $MyFreezedModelCopyWith<MyFreezedModel> get copyWith =>
      _$MyFreezedModelCopyWithImpl<MyFreezedModel>(this, _$identity);
}

abstract class MyFreezedModel implements FreezedModel {
  const factory MyFreezedModel({int? id, required String name}) =
      _$MyFreezedModel;

  @override
  int? get id => throw _privateConstructorUsedError;
  @override
  String get name => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  $MyFreezedModelCopyWith<MyFreezedModel> get copyWith =>
      throw _privateConstructorUsedError;
}
