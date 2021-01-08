import 'package:build/build.dart';
import 'package:isar_generator/src/code_gen/isar_code_generator.dart';
import 'src/isar_analyzer.dart';

Builder getIsarAnalyzer(BuilderOptions options) => IsarAnalyzer();

Builder getIsarCodeGenerator(BuilderOptions options) =>
    IsarCodeGenerator(options.config['flutter'] ?? true);
