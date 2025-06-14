// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'flutter_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$FlutterDetailEvent {
  int get id => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int id) flutterWhatsNewDetailRequested,
    required TResult Function(int id) flutterReleaseNotesDetailRequested,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int id)? flutterWhatsNewDetailRequested,
    TResult Function(int id)? flutterReleaseNotesDetailRequested,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int id)? flutterWhatsNewDetailRequested,
    TResult Function(int id)? flutterReleaseNotesDetailRequested,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_FlutterWhatsNewDetailRequested value)
        flutterWhatsNewDetailRequested,
    required TResult Function(_FlutterReleaseNotesDetailRequested value)
        flutterReleaseNotesDetailRequested,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_FlutterWhatsNewDetailRequested value)?
        flutterWhatsNewDetailRequested,
    TResult Function(_FlutterReleaseNotesDetailRequested value)?
        flutterReleaseNotesDetailRequested,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_FlutterWhatsNewDetailRequested value)?
        flutterWhatsNewDetailRequested,
    TResult Function(_FlutterReleaseNotesDetailRequested value)?
        flutterReleaseNotesDetailRequested,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FlutterDetailEventCopyWith<FlutterDetailEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FlutterDetailEventCopyWith<$Res> {
  factory $FlutterDetailEventCopyWith(
          FlutterDetailEvent value, $Res Function(FlutterDetailEvent) then) =
      _$FlutterDetailEventCopyWithImpl<$Res>;
  $Res call({int id});
}

/// @nodoc
class _$FlutterDetailEventCopyWithImpl<$Res>
    implements $FlutterDetailEventCopyWith<$Res> {
  _$FlutterDetailEventCopyWithImpl(this._value, this._then);

  final FlutterDetailEvent _value;
  // ignore: unused_field
  final $Res Function(FlutterDetailEvent) _then;

  @override
  $Res call({
    Object? id = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$$_FlutterWhatsNewDetailRequestedCopyWith<$Res>
    implements $FlutterDetailEventCopyWith<$Res> {
  factory _$$_FlutterWhatsNewDetailRequestedCopyWith(
          _$_FlutterWhatsNewDetailRequested value,
          $Res Function(_$_FlutterWhatsNewDetailRequested) then) =
      __$$_FlutterWhatsNewDetailRequestedCopyWithImpl<$Res>;
  @override
  $Res call({int id});
}

/// @nodoc
class __$$_FlutterWhatsNewDetailRequestedCopyWithImpl<$Res>
    extends _$FlutterDetailEventCopyWithImpl<$Res>
    implements _$$_FlutterWhatsNewDetailRequestedCopyWith<$Res> {
  __$$_FlutterWhatsNewDetailRequestedCopyWithImpl(
      _$_FlutterWhatsNewDetailRequested _value,
      $Res Function(_$_FlutterWhatsNewDetailRequested) _then)
      : super(_value, (v) => _then(v as _$_FlutterWhatsNewDetailRequested));

  @override
  _$_FlutterWhatsNewDetailRequested get _value =>
      super._value as _$_FlutterWhatsNewDetailRequested;

  @override
  $Res call({
    Object? id = freezed,
  }) {
    return _then(_$_FlutterWhatsNewDetailRequested(
      id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_FlutterWhatsNewDetailRequested
    implements _FlutterWhatsNewDetailRequested {
  const _$_FlutterWhatsNewDetailRequested(this.id);

  @override
  final int id;

  @override
  String toString() {
    return 'FlutterDetailEvent.flutterWhatsNewDetailRequested(id: $id)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_FlutterWhatsNewDetailRequested &&
            const DeepCollectionEquality().equals(other.id, id));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(id));

  @JsonKey(ignore: true)
  @override
  _$$_FlutterWhatsNewDetailRequestedCopyWith<_$_FlutterWhatsNewDetailRequested>
      get copyWith => __$$_FlutterWhatsNewDetailRequestedCopyWithImpl<
          _$_FlutterWhatsNewDetailRequested>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int id) flutterWhatsNewDetailRequested,
    required TResult Function(int id) flutterReleaseNotesDetailRequested,
  }) {
    return flutterWhatsNewDetailRequested(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int id)? flutterWhatsNewDetailRequested,
    TResult Function(int id)? flutterReleaseNotesDetailRequested,
  }) {
    return flutterWhatsNewDetailRequested?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int id)? flutterWhatsNewDetailRequested,
    TResult Function(int id)? flutterReleaseNotesDetailRequested,
    required TResult orElse(),
  }) {
    if (flutterWhatsNewDetailRequested != null) {
      return flutterWhatsNewDetailRequested(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_FlutterWhatsNewDetailRequested value)
        flutterWhatsNewDetailRequested,
    required TResult Function(_FlutterReleaseNotesDetailRequested value)
        flutterReleaseNotesDetailRequested,
  }) {
    return flutterWhatsNewDetailRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_FlutterWhatsNewDetailRequested value)?
        flutterWhatsNewDetailRequested,
    TResult Function(_FlutterReleaseNotesDetailRequested value)?
        flutterReleaseNotesDetailRequested,
  }) {
    return flutterWhatsNewDetailRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_FlutterWhatsNewDetailRequested value)?
        flutterWhatsNewDetailRequested,
    TResult Function(_FlutterReleaseNotesDetailRequested value)?
        flutterReleaseNotesDetailRequested,
    required TResult orElse(),
  }) {
    if (flutterWhatsNewDetailRequested != null) {
      return flutterWhatsNewDetailRequested(this);
    }
    return orElse();
  }
}

abstract class _FlutterWhatsNewDetailRequested implements FlutterDetailEvent {
  const factory _FlutterWhatsNewDetailRequested(final int id) =
      _$_FlutterWhatsNewDetailRequested;

  @override
  int get id;
  @override
  @JsonKey(ignore: true)
  _$$_FlutterWhatsNewDetailRequestedCopyWith<_$_FlutterWhatsNewDetailRequested>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_FlutterReleaseNotesDetailRequestedCopyWith<$Res>
    implements $FlutterDetailEventCopyWith<$Res> {
  factory _$$_FlutterReleaseNotesDetailRequestedCopyWith(
          _$_FlutterReleaseNotesDetailRequested value,
          $Res Function(_$_FlutterReleaseNotesDetailRequested) then) =
      __$$_FlutterReleaseNotesDetailRequestedCopyWithImpl<$Res>;
  @override
  $Res call({int id});
}

/// @nodoc
class __$$_FlutterReleaseNotesDetailRequestedCopyWithImpl<$Res>
    extends _$FlutterDetailEventCopyWithImpl<$Res>
    implements _$$_FlutterReleaseNotesDetailRequestedCopyWith<$Res> {
  __$$_FlutterReleaseNotesDetailRequestedCopyWithImpl(
      _$_FlutterReleaseNotesDetailRequested _value,
      $Res Function(_$_FlutterReleaseNotesDetailRequested) _then)
      : super(_value, (v) => _then(v as _$_FlutterReleaseNotesDetailRequested));

  @override
  _$_FlutterReleaseNotesDetailRequested get _value =>
      super._value as _$_FlutterReleaseNotesDetailRequested;

  @override
  $Res call({
    Object? id = freezed,
  }) {
    return _then(_$_FlutterReleaseNotesDetailRequested(
      id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_FlutterReleaseNotesDetailRequested
    implements _FlutterReleaseNotesDetailRequested {
  const _$_FlutterReleaseNotesDetailRequested(this.id);

  @override
  final int id;

  @override
  String toString() {
    return 'FlutterDetailEvent.flutterReleaseNotesDetailRequested(id: $id)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_FlutterReleaseNotesDetailRequested &&
            const DeepCollectionEquality().equals(other.id, id));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(id));

  @JsonKey(ignore: true)
  @override
  _$$_FlutterReleaseNotesDetailRequestedCopyWith<
          _$_FlutterReleaseNotesDetailRequested>
      get copyWith => __$$_FlutterReleaseNotesDetailRequestedCopyWithImpl<
          _$_FlutterReleaseNotesDetailRequested>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int id) flutterWhatsNewDetailRequested,
    required TResult Function(int id) flutterReleaseNotesDetailRequested,
  }) {
    return flutterReleaseNotesDetailRequested(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function(int id)? flutterWhatsNewDetailRequested,
    TResult Function(int id)? flutterReleaseNotesDetailRequested,
  }) {
    return flutterReleaseNotesDetailRequested?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int id)? flutterWhatsNewDetailRequested,
    TResult Function(int id)? flutterReleaseNotesDetailRequested,
    required TResult orElse(),
  }) {
    if (flutterReleaseNotesDetailRequested != null) {
      return flutterReleaseNotesDetailRequested(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_FlutterWhatsNewDetailRequested value)
        flutterWhatsNewDetailRequested,
    required TResult Function(_FlutterReleaseNotesDetailRequested value)
        flutterReleaseNotesDetailRequested,
  }) {
    return flutterReleaseNotesDetailRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_FlutterWhatsNewDetailRequested value)?
        flutterWhatsNewDetailRequested,
    TResult Function(_FlutterReleaseNotesDetailRequested value)?
        flutterReleaseNotesDetailRequested,
  }) {
    return flutterReleaseNotesDetailRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_FlutterWhatsNewDetailRequested value)?
        flutterWhatsNewDetailRequested,
    TResult Function(_FlutterReleaseNotesDetailRequested value)?
        flutterReleaseNotesDetailRequested,
    required TResult orElse(),
  }) {
    if (flutterReleaseNotesDetailRequested != null) {
      return flutterReleaseNotesDetailRequested(this);
    }
    return orElse();
  }
}

abstract class _FlutterReleaseNotesDetailRequested
    implements FlutterDetailEvent {
  const factory _FlutterReleaseNotesDetailRequested(final int id) =
      _$_FlutterReleaseNotesDetailRequested;

  @override
  int get id;
  @override
  @JsonKey(ignore: true)
  _$$_FlutterReleaseNotesDetailRequestedCopyWith<
          _$_FlutterReleaseNotesDetailRequested>
      get copyWith => throw _privateConstructorUsedError;
}
