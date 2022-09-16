class IsarObject {
  const IsarObject({
    required this.collection,
    this.path = '',
    required this.data,
  });

  final String collection;
  final String path;
  final Map<String, dynamic> data;

  dynamic getValue(String propertyName) => data[propertyName];

  IsarObject? getNested(String propertyName, {String? linkCollection}) {
    final data = this.data[propertyName] as Map<String, dynamic>;
    return IsarObject(
      collection: linkCollection ?? data['collection'] as String,
      path: linkCollection == null ? '$path.$propertyName' : '',
      data: data,
    );
  }

  List<IsarObject?>? getNestedList(
    String propertyName, {
    String? linkCollection,
  }) {
    final list = data[propertyName] as List<dynamic>?;
    if (list == null) {
      return null;
    }

    final objects = <IsarObject?>[];
    for (var i = 0; i < list.length; i++) {
      final data = list[i] as Map<String, dynamic>;
      objects.add(
        IsarObject(
          collection: linkCollection ?? collection,
          path: linkCollection == null ? '$path.$i' : '',
          data: data,
        ),
      );
    }

    return objects;
  }
}
