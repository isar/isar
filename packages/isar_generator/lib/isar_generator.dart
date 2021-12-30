import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/collection_generator.dart';

Builder getIsarGenerator(BuilderOptions options) =>
    SharedPartBuilder([IsarCollectionGenerator()], 'isar_generator');
