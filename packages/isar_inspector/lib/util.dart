import 'package:isar/isar.dart';

extension CollectionInfoX on IsarSchema {
  List<IsarPropertySchema> get idAndProperties {
    final props = [
      if (!this.embedded && !properties.any((e) => e.name == idName))
        IsarPropertySchema(name: idName!, type: IsarType.long),
      ...properties,
    ];
    props.sort((a, b) {
      if (a.name == idName) {
        return -1;
      } else if (b.name == idName) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });
    return props;
  }
}
