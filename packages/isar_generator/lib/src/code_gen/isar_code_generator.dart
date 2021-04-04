import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:isar_generator/src/code_gen/isar_interface_generator.dart';
import 'package:isar_generator/src/code_gen/object_adapter_generator.dart';
import 'package:isar_generator/src/code_gen/query_distinct_by_generator.dart';
import 'package:isar_generator/src/code_gen/query_link_generator.dart';
import 'package:isar_generator/src/code_gen/query_property_generator.dart';
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
    'package:isar/src/isar_native.dart',
    'package:isar/src/isar_interface.dart',
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

    var rawObjects = files.values.flatten().toList();

    for (var m in rawObjects) {
      for (var m2 in rawObjects) {
        if (m != m2 && m.isarName == m2.isarName) {
          err('There are two objects with the same name: "${m.isarName}"');
        }
      }
    }

    final objects = rawObjects.map((object) {
      final links = <ObjectLink>[];
      var linkIndex = 0;
      for (var link in object.links) {
        var index = 0;
        if (link.backlink) {
          final targetCol = rawObjects
              .where((it) => it.dartName == link.targetCollectionDartName)
              .first;
          var targetIndex = 0;
          for (var targetLink in targetCol.links) {
            if (link.targetDartName == targetLink.dartName) {
              index = targetIndex;
              break;
            } else if (!targetLink.backlink) {
              targetIndex++;
            }
          }
        } else {
          index = linkIndex++;
        }
        links.add(link.copyWith(linkIndex: index));
      }
      return object.copyWith(links: links);
    }).toList();

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
            'final ${oi.collectionVar} = <String, IsarCollection<${oi.dartName}>>{};')
        .join('\n');
    final objectAdapters =
        objects.map((o) => generateObjectAdapter(o)).join('\n');
    final getCollectionsExtensions = generateGetCollectionsExtension(objects);
    final queryWhereExtensions =
        objects.map((o) => generateQueryWhere(o)).join('\n');
    final queryFilterExtensions =
        objects.map((o) => generateQueryFilter(o)).join('\n');
    final queryLinkExtensions =
        objects.map((o) => generateQueryLinks(o, objects)).join('\n');
    final querySortByExtensions =
        objects.map((o) => generateSortBy(o)).join('\n');
    final queryDistinctByExtensions =
        objects.map((o) => generateDistinctBy(o)).join('\n');
    final propertyQueries =
        objects.map((o) => generatePropertyQuery(o)).join('\n');

    var code = '''
    // ignore_for_file: unused_import, implementation_imports

    $imports

    final _isar = <String, Isar>{};
    const _utf8Encoder = Utf8Encoder();

    ${generateIsarSchema(objects)}

    $collectionVars

    ${generateIsarOpen(objects)}

    ${generatePreparePath()}

    $getCollectionsExtensions

    $objectAdapters

    $queryWhereExtensions
    $queryFilterExtensions
    $queryLinkExtensions
    $querySortByExtensions
    $queryDistinctByExtensions
    $propertyQueries

    ${generateIsarInterface(objects)}
    ''';

    code = DartFormatter().format(code);

    final codeId =
        AssetId(buildStep.inputId.package, '${dir(buildStep)}/isar.g.dart');
    await buildStep.writeAsString(codeId, code);
  }

  String generateIsarOpen(List<ObjectInfo> objects) {
    var code = '''
    Future<Isar> openIsar({String name = 'isar', String? directory, int maxSize = 1000000000, Uint8List? encryptionKey}) async {
      assert(name.isNotEmpty);
      final path = await _preparePath(directory);
      if (_isar[name] != null) {
        return _isar[name]!;
      }
      await Directory(p.join(path, name)).create(recursive: true);
      initializeIsarCore();
      IC.isar_connect_dart_api(NativeApi.postCObject);

      final isarPtrPtr = malloc<Pointer>();
      final namePtr = name.toNativeUtf8();
      final pathPtr = path.toNativeUtf8();
      IC.isar_get_instance(isarPtrPtr, namePtr.cast());
      if (isarPtrPtr.value.address == 0) {
        final schemaPtr = _schema.toNativeUtf8();
        var encKeyPtr = Pointer<Uint8>.fromAddress(0);
        if (encryptionKey != null) {
          assert(encryptionKey.length == 32,
              'Encryption keys need to contain 32 byte (256bit).');
          encKeyPtr = malloc(32);
          encKeyPtr.asTypedList(32).setAll(0, encryptionKey);
        }
        final receivePort = ReceivePort();
        final nativePort = receivePort.sendPort.nativePort;
        final stream = wrapIsarPort(receivePort);
        IC.isar_create_instance(isarPtrPtr, namePtr.cast(), pathPtr.cast(), maxSize,
            schemaPtr.cast(), encKeyPtr, nativePort);
        await stream.first;
        malloc.free(schemaPtr);
        if (encryptionKey != null) {
          malloc.free(encKeyPtr);
        }
      }
      malloc.free(namePtr);
      malloc.free(pathPtr);
      
      final isarPtr = isarPtrPtr.value;
      malloc.free(isarPtrPtr);

      final isar = IsarImpl(name, isarPtr);
      _isar[name] = isar;
      
      final collectionPtrPtr = malloc<Pointer>();
    ''';

    final maxProperties =
        objects.maxBy((e) => e.properties.length)?.properties.length ?? 0;
    code += '''
    final propertyOffsetsPtr = malloc<Uint32>($maxProperties);
    final propertyOffsets = propertyOffsetsPtr.asTypedList($maxProperties);
    ''';

    for (var i = 0; i < objects.length; i++) {
      final info = objects[i];
      code += '''
      nCall(IC.isar_get_collection(isarPtr, collectionPtrPtr, $i));
      IC.isar_get_property_offsets(collectionPtrPtr.value, propertyOffsetsPtr);
      ${info.collectionVar}[name] = IsarCollectionImpl(
        isar,
        _${info.dartName}Adapter(),
        collectionPtrPtr.value,
        propertyOffsets.sublist(0, ${info.properties.length}),
        (obj) => obj.${info.oidProperty.dartName},
        (obj, id) => obj.${info.oidProperty.dartName} = id,
      );''';
    }

    code += '''
      malloc.free(propertyOffsetsPtr);
      malloc.free(collectionPtrPtr);

      IsarInterface.initialize(_GeneratedIsarInterface());
      Isar.addCloseListener(_onClose);

      return isar;
    }

    void _onClose(String name) {
      _isar.remove(name);
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

  String generateGetCollectionsExtension(List<ObjectInfo> objects) {
    var code = 'extension GetCollection on Isar {';
    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      code += '''
      IsarCollection<${object.dartName}> get ${object.dartName.decapitalize()}s {
        return ${object.collectionVar}[name]!;
      }
      ''';
    }
    return '$code}';
  }

  String generateIsarSchema(List<ObjectInfo> ois) {
    final jsonMap = [
      for (var oi in ois)
        {
          'name': oi.isarName,
          'idProperty': oi.properties.firstWhere((it) => it.isId).isarName,
          'properties': [
            for (var property in oi.properties)
              {
                'name': property.isarName,
                'type': property.isarType.typeId,
              },
          ],
          'indexes': [
            for (var index in oi.indexes)
              {
                'unique': index.unique,
                'replace': index.replace,
                'properties': [
                  for (var indexProperty in index.properties!)
                    {
                      'name': indexProperty.property.isarName,
                      'indexType': indexProperty.indexType.index,
                      'caseSensitive': indexProperty.caseSensitive,
                    }
                ]
              }
          ],
          'links': [
            for (var link in oi.links) ...[
              if (!link.backlink)
                {
                  'name': link.isarName,
                  'collection': ois
                      .firstWhere(
                          (it) => it.dartName == link.targetCollectionDartName)
                      .isarName,
                }
            ]
          ]
        },
    ];
    final json = jsonEncode(jsonMap);
    return "final _schema = '$json';";
  }
}
