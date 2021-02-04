import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:isar_annotation/isar_annotation.dart';
import 'package:isar_generator/src/code_gen/object_adapter_generator.dart';
import 'package:isar_generator/src/code_gen/util.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:isar_generator/src/code_gen/query_filter_generator.dart';
import 'package:isar_generator/src/code_gen/query_where_generator.dart';
import 'package:path/path.dart' as path;
import 'package:dartx/dartx.dart';

class IsarCodeGenerator extends Builder {
  final bool isFlutter;

  IsarCodeGenerator(this.isFlutter);

  @override
  final buildExtensions = {
    r'$lib$': ['isar.g.dart'],
    r'$test$': ['isar.g.dart']
  };

  String dir(BuildStep buildStep) => path.dirname(buildStep.inputId.path);

  static const imports = [
    'dart:ffi',
    'dart:convert',
    'dart:isolate',
    'dart:typed_data',
    'dart:io',
    'package:isar/isar.dart',
    'package:isar/isar_native.dart',
    'package:ffi/ffi.dart',
    "import 'package:path/path.dart' as p",
  ];

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final files = <String, Iterable<ObjectInfo>>{};
    final glob = Glob(dir(buildStep) + '/**.isarobject.json');
    await for (final input in buildStep.findAssets(glob)) {
      var json = JsonDecoder().convert(await buildStep.readAsString(input));
      files[input.path] =
          (json as Iterable).map((it) => ObjectInfo.fromJson(it));
    }
    if (files.isEmpty) return;

    var fileImports = files.keys.map((path) => path
        .replaceAll('\\', '/')
        .replaceFirst('lib/', '')
        .replaceFirst('test/', '')
        .replaceAll('.isarobject.json', '.dart'));

    var objects = files.values.flatten().toList();

    for (var m in objects) {
      for (var m2 in objects) {
        if (m != m2 && m.isarName == m2.isarName) {
          err('There are two objects with the same name: "${m.isarName}"');
        }
      }
    }

    var imports = {
      ...IsarCodeGenerator.imports,
      ...fileImports,
      if (isFlutter) ...{
        'package:path_provider/path_provider.dart',
        'package:flutter/widgets.dart'
      },
      for (var object in objects) ...object.converterImports,
    }
        .map((im) => im.startsWith('import') ? '$im;' : "import '$im';")
        .join('\n');

    final collectionVars = objects
        .map((o) =>
            'final ${getCollectionVar(o.dartName)} = <String, IsarCollection<${o.oidProperty.dartTypeNotNull}, ${o.dartName}>>{};')
        .join('\n');
    final objectAdapters =
        objects.map((o) => generateObjectAdapter(o)).join('\n');
    final getCollectionExtensions = objects
        .mapIndexed((i, o) => generateGetCollectionExtension(o, i))
        .join('\n');
    final queryWhereExtensions =
        objects.map((o) => generateQueryWhere(o)).join('\n');
    final queryFilterExtensions =
        objects.map((o) => generateQueryFilter(o)).join('\n');

    var code = '''
    $imports

    export 'package:isar/isar.dart';

    final _isar = <String, Isar>{};
    const _utf8Encoder = Utf8Encoder();

    $collectionVars
    ${generateIsarOpen(objects)}
    ${generatePreparePath()}

    $getCollectionExtensions

    $objectAdapters

    $queryWhereExtensions
    $queryFilterExtensions
    ''';

    code = DartFormatter().format(code);

    final codeId =
        AssetId(buildStep.inputId.package, '${dir(buildStep)}/isar.g.dart');
    await buildStep.writeAsString(codeId, code);
  }

  String generateIsarOpen(List<ObjectInfo> objects) {
    var code = '''
    Future<Isar> openIsar({String? directory, int maxSize = 1000000000}) async {
      final path = await _preparePath(directory);
      if (_isar[path] != null) {
        return _isar[path]!;
      }
      await Directory(path).create(recursive: true);
      initializeIsarCore();
      IC.isar_connect_dart_api(NativeApi.postCObject);
      final schemaPtr = IC.isar_schema_create();
      final collectionPtrPtr = allocate<Pointer>();
    ''';

    for (var info in objects) {
      code += '''
      {
        final namePtr = Utf8.toUtf8('${info.isarName}');
        final idNamePtr = Utf8.toUtf8('${info.oidProperty.isarName}');
        nCall(IC.isar_schema_create_collection(
          collectionPtrPtr,
          namePtr.cast(),
          idNamePtr.cast(),
          ${info.oidProperty.isarType.typeId},
        ));
        final collectionPtr = collectionPtrPtr.value;
        free(namePtr);
        free(idNamePtr);
      ''';
      for (var property in info.properties) {
        code += '''
        {
          final pNamePtr = Utf8.toUtf8('${property.isarName}');
          nCall(IC.isar_schema_add_property(collectionPtr, pNamePtr.cast(), ${property.isarType.typeId}));
          free(pNamePtr);
        }
        ''';
      }
      for (var index in info.indices) {
        code += '''
        {
          final propertiesPtrPtr = allocate<Pointer<Int8>>(count: ${index.properties.length});
          final stringTypesPtr = allocate<Uint8>(count: ${index.properties.length});
          final stringsCaseSensitivePtr = allocate<Uint8>(count: ${index.properties.length});
        ''';
        for (var i = 0; i < index.properties.length; i++) {
          final indexProperty = index.properties[i];
          final property = info.getProperty(indexProperty.isarName);
          final defaultStringType = property.isarType == IsarType.String
              ? StringIndexType.hash.index
              : 255;
          code += '''
            propertiesPtrPtr[$i] = Utf8.toUtf8('${indexProperty.isarName}').cast();
            stringTypesPtr[$i] = ${indexProperty.stringType?.index ?? defaultStringType};
            stringsCaseSensitivePtr[$i] = ${indexProperty.caseSensitive ? 1 : 0};
          ''';
        }

        code += '''
        nCall(IC.isar_schema_add_index(
          collectionPtr,
          propertiesPtrPtr,
          stringTypesPtr,
          stringsCaseSensitivePtr,
          ${index.properties.length},
          ${index.unique},
        ));''';
        for (var i = 0; i < index.properties.length; i++) {
          code += 'free(propertiesPtrPtr[$i]);';
        }
        code += '''
          free(propertiesPtrPtr);
          free(stringTypesPtr);
          free(stringsCaseSensitivePtr);
        }
        ''';
      }
      code += '''
        nCall(IC.isar_schema_add_collection(schemaPtr, collectionPtrPtr.value));
      }
      
      ''';
    }

    code += '''
      final pathPtr = Utf8.toUtf8(path);
      final isarPtrPtr = allocate<Pointer>();
      final receivePort = ReceivePort();
      final nativePort = receivePort.sendPort.nativePort;
      IC.isar_create_instance(isarPtrPtr, pathPtr.cast(), maxSize, schemaPtr, nativePort);
      await receivePort.first;
      free(pathPtr);
      
      final isarPtr = isarPtrPtr.value;
      final isar = IsarImpl(path, isarPtr);
      _isar[path] = isar;
      free(isarPtrPtr);
    ''';

    for (var i = 0; i < objects.length; i++) {
      final info = objects[i];
      code += '''
      {
        nCall(IC.isar_get_collection(isarPtr, collectionPtrPtr, $i));
        final propertyOffsets = <int>[];
      ''';
      for (var p = 0; p < info.properties.length; p++) {
        code +=
            'propertyOffsets.add(IC.isar_get_property_offset(collectionPtrPtr.value, $p));';
      }
      code += '''
        ${getCollectionVar(info.dartName)}[path] = IsarCollectionImpl(
          isar,
          _${info.dartName}Adapter(),
          collectionPtrPtr.value,
          propertyOffsets,
          (obj) => obj.${info.oidProperty.dartName},
          (obj, id) => obj.${info.oidProperty.dartName} = id,
        );
      }
      ''';
    }

    code += '''
      free(collectionPtrPtr);
      return isar;
    }
    ''';

    return code;
  }

  String generatePreparePath() {
    var code = '''
    Future<String> _preparePath(String? path) async {
      if (path == null || p.isRelative(path)) {''';
    if (isFlutter) {
      code += '''
        WidgetsFlutterBinding.ensureInitialized();
        final dir = await getApplicationDocumentsDirectory();
        return p.join(dir.path, path ?? 'isar');
        ''';
    } else {
      code += "return p.absolute(path ?? '');";
    }
    code += ''' 
      } else {
        return path;
      }
    }''';
    return code;
  }

  String generateGetCollectionExtension(ObjectInfo object, int objectIndex) {
    return '''
    extension Get${object.dartName}Collection on Isar {
      IsarCollection<${object.oidProperty.dartTypeNotNull}, ${object.dartName}> get ${object.dartName.decapitalize()}s {
        return ${getCollectionVar(object.dartName)}[path]!;
      }
    }
    ''';
  }
}
