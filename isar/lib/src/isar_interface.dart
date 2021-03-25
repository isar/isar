import 'package:isar/isar.dart';

abstract class IsarInterface {
  static IsarInterface? _instance;

  static IsarInterface? get instance => _instance;

  static void initialize(IsarInterface instance) {
    _instance = instance;
  }

  String get schemaJson;

  List<String> get instanceNames;

  IsarCollection getCollection(String instanceName, String collectionName);

  Map<String, dynamic> objectToJson(dynamic object);

  //Future put(String instanceName, String collectionName, String objectJson);
}
