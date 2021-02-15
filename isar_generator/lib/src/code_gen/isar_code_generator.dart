import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:isar_generator/src/code_gen/object_adapter_generator.dart';
import 'package:isar_generator/src/code_gen/query_distinct_by_generator.dart';
import 'package:isar_generator/src/code_gen/query_sort_by_generator.dart';
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
    'package:isar/src/query_builder.dart',
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
        .map((oi) =>
            'final ${oi.collectionVar} = <String, IsarCollection<${oi.oidProperty.dartTypeNotNull}, ${oi.dartName}>>{};')
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
    final querySortByExtensions =
        objects.map((o) => generateSortBy(o)).join('\n');
    final queryDistinctByExtensions =
        objects.map((o) => generateDistinctBy(o)).join('\n');

    var code = '''
    $imports

    export 'package:isar/isar.dart';

    final _isar = <String, Isar>{};
    const _utf8Encoder = Utf8Encoder();

    ${generateIsarSchema(objects)}

    $collectionVars

    ${generateIsarOpen(objects)}

    ${generatePreparePath()}

    $getCollectionExtensions

    $objectAdapters

    $queryWhereExtensions
    $queryFilterExtensions
    $querySortByExtensions
    $queryDistinctByExtensions
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

      final isarPtrPtr = allocate<Pointer>();
      final pathPtr = Utf8.toUtf8(path);
      IC.isar_get_instance(isarPtrPtr, pathPtr.cast());
      if (isarPtrPtr.value.address == 0) {
        final schemaPtr = Utf8.toUtf8(_schema);
        final receivePort = ReceivePort();
        final nativePort = receivePort.sendPort.nativePort;
        final stream = wrapIsarPort(receivePort);
        IC.isar_create_instance(isarPtrPtr, pathPtr.cast(), maxSize, schemaPtr.cast(), nativePort);
        await stream.first;
        free(schemaPtr);
      }
      free(pathPtr);
      
      final isarPtr = isarPtrPtr.value;
      free(isarPtrPtr);

      final isar = IsarImpl(path, isarPtr);
      _isar[path] = isar;
      
      final collectionPtrPtr = allocate<Pointer>();
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
        ${info.collectionVar}[path] = IsarCollectionImpl(
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
        return p.join(dir!.path, path ?? 'isar');
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
        return ${object.collectionVar}[path]!;
      }
    }
    ''';
  }

  String generateIsarSchema(List<ObjectInfo> ois) {
    final jsonMap = [
      for (var oi in ois)
        {
          'name': oi.isarName,
          'properties': [
            for (var property in oi.properties)
              {
                'name': property.isarName,
                'type': property.isarType.typeId,
                'isObjectId': property.isObjectId,
              },
          ],
          'indexes': [
            for (var index in oi.indexes)
              {
                'unique': index.unique,
                'properties': [
                  for (var indexProperty in index.properties)
                    {
                      'name': indexProperty.property.isarName,
                      'indexType': indexProperty.indexType.index,
                      'caseSensitive': indexProperty.caseSensitive,
                    }
                ]
              }
          ]
        },
    ];
    final json = jsonEncode(jsonMap);
    return "final _schema = '$json';";
  }
}
