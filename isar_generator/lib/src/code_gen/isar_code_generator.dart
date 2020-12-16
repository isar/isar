import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:isar_generator/src/code_gen/object_adapter_generator.dart';
import 'package:isar_generator/src/code_gen/util.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:isar_generator/src/code_gen/query_filter_generator.dart';
import 'package:isar_generator/src/code_gen/query_where_generator.dart';
import 'package:path/path.dart' as path;
import 'package:dartx/dartx.dart';

class IsarCodeGenerator extends Builder {
  @override
  final buildExtensions = {
    r'$lib$': ['isar.g.dart'],
    r'$test$': ['isar.g.dart']
  };

  String dir(BuildStep buildStep) => path.dirname(buildStep.inputId.path);

  static const imports = [
    'dart:ffi',
    'dart:convert',
    'dart:typed_data',
    'package:isar/internal.dart',
    'package:ffi/ffi.dart'
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
        .replaceAll('.isarobject.json', '.dart'));

    var imports = [IsarCodeGenerator.imports, fileImports]
        .flatten()
        .map((im) => 'import "$im";')
        .join('\n');

    var objects = files.values.flatten().toList();

    for (var m in objects) {
      for (var m2 in objects) {
        if (m != m2 && m.dbName == m2.dbName) {
          err('There are two objects with the same name: "${m.dbName}"');
        }
      }
    }

    var schemaJson =
        JsonEncoder().convert(objects.map((o) => o.toJson()).toList());
    var collectionVars = objects
        .map((o) => 'IsarCollection<${o.type}> ${getCollectionVar(o.type)};')
        .join('\n');
    var objectAdapters =
        objects.map((o) => generateObjectAdapter(o)).join('\n');
    var getCollectionExtensions = objects
        .mapIndexed((i, o) => generateGetCollectionExtension(o, i))
        .join('\n');
    var queryWhereExtensions =
        objects.map((o) => generateQueryWhere(o)).join('\n');
    var queryFilterExtensions =
        objects.map((o) => generateQueryFilter(o)).join('\n');

    var code = '''
    $imports

    export 'package:isar/isar.dart';

    const utf8Encoder = Utf8Encoder();

    $collectionVars
    ${generateIsarOpen(objects)}
        

    $objectAdapters

    const _schema = '$schemaJson';
    ''';

    //$getCollectionExtensions
    //$queryWhereExtensions
    //$queryFilterExtensions

    print(code);
    code = DartFormatter().format(code);

    final codeId =
        AssetId(buildStep.inputId.package, '${dir(buildStep)}/isar.g.dart');
    await buildStep.writeAsString(codeId, code);
  }

  String generateIsarOpen(Iterable<ObjectInfo> objects) {
    var initializeCollectionVars = objects.mapIndexed((i, o) {
      return '''
      nativeCall(isarBindings.getCollection(isar, collectionPtr, $i));
      ${getCollectionVar(o.type)} = IsarCollectionImpl(this, _${o.type}Adapter(), collectionPtr.value);
      ''';
    }).join('\n');

    return '''
    Isar open(String path) {
      var pathPtr = Utf8.toUtf8(path);
      var schemaPtr = Utf8.toUtf8(_schema);
      var isarPtr = IsarBindings.ptr;
      nativeCall(isarBindings.createInstance(isarPtr, pathPtr, 1000000, schemaPtr));
      free(pathPtr);
      free(schemaPtr);

      var isar = isarPtr.value;
      var collectionPtr = IsarBindings.ptr;
      $initializeCollectionVars

      return IsarImpl(isar);
    }
    ''';
  }

  String generateGetCollectionExtension(ObjectInfo object, int objectIndex) {
    return '''
    extension Get${object.type}Collection on Isar {
      IsarCollection<${object.type}> get ${object.type.decapitalize()}s {
        return ${getCollectionVar(object.type)};
      }
    }
    ''';
  }

  String boolToU8(bool value) {
    if (value) {
      return '1';
    } else {
      return '0';
    }
  }
}
