import "package:build/build.dart";
import 'src/isar_analyzer.dart';
import 'src/isar_code_generator.dart';

Builder getIsarAnalyzer(BuilderOptions options) => IsarAnalyzer();

Builder getIsarCodeGenerator(BuilderOptions options) => IsarCodeGenerator();
