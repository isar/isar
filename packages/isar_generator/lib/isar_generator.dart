import 'package:build/build.dart';
import 'package:isar_generator/src/code_gen/isar_code_generator.dart';
import 'src/isar_analyzer.dart';

Builder getIsarAnalyzer(BuilderOptions options) => IsarAnalyzer();

Builder getIsarGenerator(BuilderOptions options) => IsarCodeGenerator(
      flutter: options.config['flutter'] ?? true,
      package: options.config['package'] ?? false,
      extensions: options.config['extensions'] ?? true,
    );
