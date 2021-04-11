import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
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
  final bool flutter;
  final bool package;
  final bool extensions;

  IsarCodeGenerator({
    required this.flutter,
    required this.package,
    required this.extensions,
  });

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
      if (flutter) ...{
        'package:path_provider/path_provider.dart',
        'package:flutter/widgets.dart'
      },
      for (var object in objects) ...object.imports,
    }
        .map((im) => im.startsWith('import') ? '$im;' : "import '$im';")
        .join('\n');

    var code = '''
    // ignore_for_file: unused_import, implementation_imports

    $imports
    ''';

    if (!package) {
      final objectAdapters =
          objects.map((o) => generateObjectAdapter(o)).join('\n');

      code += '''
        const _utf8Encoder = Utf8Encoder();

        ${generateIsarSchema(objects)}

        ${generateIsarOpen(objects)}

        ${generatePreparePath()}

        $objectAdapters''';
    }

    if (extensions) {
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

      code += '''
        $getCollectionsExtensions
        $queryWhereExtensions
        $queryFilterExtensions
        $queryLinkExtensions
        $querySortByExtensions
        $queryDistinctByExtensions
        $propertyQueries''';
    }

    code = DartFormatter().format(code);

    final codeId =
        AssetId(buildStep.inputId.package, '${dir(buildStep)}/isar.g.dart');
    await buildStep.writeAsString(codeId, code);
  }

  String generateIsarOpen(List<ObjectInfo> objects) {
    var code = '''
    Future<Isar> openIsar({String name = 'isar', String? directory, int maxSize = 1000000000, Uint8List? encryptionKey}) async {
      final path = await _preparePath(directory);
      return openIsarInternal(
        name: name,
        directory: path,
        maxSize: maxSize,
        encryptionKey: encryptionKey,
        schema: _schema,
        getCollections: (isar) {''';

    final maxProperties =
        objects.maxBy((e) => e.properties.length)?.properties.length ?? 0;
    code += '''
    final collectionPtrPtr = malloc<Pointer>();
    final propertyOffsetsPtr = malloc<Uint32>($maxProperties);
    final propertyOffsets = propertyOffsetsPtr.asTypedList($maxProperties);
    final collections = <String, IsarCollection>{};
    ''';

    for (var i = 0; i < objects.length; i++) {
      final info = objects[i];
      final propertyIds = info.properties
          .mapIndexed((index, p) => "'${p.dartName}': $index")
          .join(',');
      final indexIds = info.indexes
          .mapIndexed(
              (index, i) => "'${i.properties.first.property.dartName}': $index")
          .join(',');
      final linkIds = info.links
          .where((l) => !l.backlink)
          .map((link) => "'${link.dartName}': ${link.linkIndex}")
          .join(',');
      final backlinkIds = info.links
          .where((l) => l.backlink)
          .map((link) => "'${link.dartName}': ${link.linkIndex}")
          .join(',');
      code += '''
      nCall(IC.isar_get_collection(isar.ptr, collectionPtrPtr, $i));
      IC.isar_get_property_offsets(collectionPtrPtr.value, propertyOffsetsPtr);
      collections['${info.dartName}'] = IsarCollectionImpl<${info.dartName}>(
        isar: isar,
        adapter: _${info.dartName}Adapter(),
        ptr: collectionPtrPtr.value,
        propertyOffsets: propertyOffsets.sublist(0, ${info.properties.length}),
        propertyIds: {$propertyIds},
        indexIds: {$indexIds},
        linkIds: {$linkIds},
        backlinkIds: {$backlinkIds},
        getId: (obj) => obj.${info.oidProperty.dartName},
        setId: (obj, id) => obj.${info.oidProperty.dartName} = id,
      );''';
    }

    code += '''
      malloc.free(propertyOffsetsPtr);
      malloc.free(collectionPtrPtr);

      return collections;
    });
    }
    ''';

    return code;
  }

  String generatePreparePath() {
    var code = '''
    Future<String> _preparePath(String? path) async {
      if (path == null || p.isRelative(path)) {''';
    if (flutter) {
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
        return getCollection('${object.dartName}');
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
                  for (var indexProperty in index.properties)
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
