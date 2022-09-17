import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/object/property_value.dart';
import 'package:isar_inspector/util.dart';

class QueryFilter extends StatelessWidget {
  const QueryFilter({
    super.key,
    required this.collection,
    required this.condition,
    required this.onChanged,
  });

  final CollectionSchema<dynamic> collection;
  final FilterCondition condition;
  final void Function(FilterCondition filter) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final property = collection.propertyOrId(condition.property);
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                items: [
                  for (final property in collection.idAndProperties)
                    if (property.type != IsarType.object &&
                        property.type != IsarType.objectList)
                      DropdownMenuItem(
                        value: property.name,
                        child: Text(property.name),
                      ),
                ],
                value: condition.property,
                onChanged: (value) {
                  if (value == null) return;
                  final newProperty = collection.propertyOrId(value);
                  onChanged(
                    FilterCondition(
                      type: FilterConditionType.equalTo,
                      property: value,
                      value1: newProperty.defaultEditingValue,
                      value2: newProperty.defaultEditingValue,
                      include1: false,
                      include2: false,
                      caseSensitive: false,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            DropdownButtonHideUnderline(
              child: DropdownButton<FilterConditionType>(
                isDense: true,
                items: [
                  for (final type in property.supportedFilters)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.niceName),
                    ),
                ],
                value: condition.type,
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(
                    FilterCondition(
                      type: value,
                      property: condition.property,
                      value1: condition.value1,
                      include1: value == FilterConditionType.between,
                      value2: condition.value2,
                      include2: value == FilterConditionType.between,
                      caseSensitive: false,
                    ),
                  );
                },
              ),
            ),
            if (condition.type.valueCount > 0) ...[
              const SizedBox(width: 20),
              SizedBox(
                width: 100,
                child: PropertyValue(
                  condition.value1,
                  type: property.type,
                  enumMap: property.enumMap,
                  onUpdate: (newValue) {
                    onChanged(
                      FilterCondition(
                        type: condition.type,
                        property: condition.property,
                        value1: newValue,
                        include1: condition.include1,
                        value2: condition.value2,
                        include2: condition.include2,
                        caseSensitive: false,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (condition.type.valueCount == 2) ...[
              const SizedBox(width: 20),
              SizedBox(
                width: 100,
                child: PropertyValue(
                  condition.value2,
                  type: property.type,
                  enumMap: property.enumMap,
                  onUpdate: (newValue) {
                    onChanged(
                      FilterCondition(
                        type: condition.type,
                        property: condition.property,
                        value1: condition.value1,
                        include1: condition.include1,
                        value2: newValue,
                        include2: condition.include2,
                        caseSensitive: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  dynamic get value1 {}
}

extension on PropertySchema {
  List<FilterConditionType> get supportedFilters {
    switch (type) {
      case IsarType.bool:
      case IsarType.boolList:
        return [
          FilterConditionType.equalTo,
          FilterConditionType.isNull,
          FilterConditionType.isNotNull,
          if (type == IsarType.boolList) ...[
            FilterConditionType.elementIsNull,
            FilterConditionType.elementIsNotNull,
            FilterConditionType.listLength,
          ],
        ];
      case IsarType.byte:
      case IsarType.byteList:
        return [
          FilterConditionType.equalTo,
          FilterConditionType.greaterThan,
          FilterConditionType.lessThan,
          FilterConditionType.between,
          if (type == IsarType.byteList) FilterConditionType.listLength,
        ];
      case IsarType.int:
      case IsarType.float:
      case IsarType.long:
      case IsarType.double:
      case IsarType.dateTime:
      case IsarType.intList:
      case IsarType.floatList:
      case IsarType.longList:
      case IsarType.doubleList:
      case IsarType.dateTimeList:
        return [
          FilterConditionType.equalTo,
          FilterConditionType.greaterThan,
          FilterConditionType.lessThan,
          FilterConditionType.between,
          FilterConditionType.isNull,
          FilterConditionType.isNotNull,
          FilterConditionType.elementIsNull,
          FilterConditionType.elementIsNotNull,
          FilterConditionType.listLength,
        ];
      case IsarType.string:
      case IsarType.stringList:
        return [
          FilterConditionType.equalTo,
          FilterConditionType.greaterThan,
          FilterConditionType.lessThan,
          FilterConditionType.between,
          FilterConditionType.startsWith,
          FilterConditionType.endsWith,
          FilterConditionType.contains,
          FilterConditionType.matches,
          FilterConditionType.isNull,
          FilterConditionType.isNotNull,
          if (type == IsarType.stringList) ...[
            FilterConditionType.elementIsNull,
            FilterConditionType.elementIsNotNull,
            FilterConditionType.listLength,
          ],
        ];
      case IsarType.object:
      case IsarType.objectList:
        return [];
    }
  }

  dynamic get defaultEditingValue {
    if (enumMap != null) {
      return enumMap!.values.first;
    }
    switch (type) {
      case IsarType.bool:
      case IsarType.boolList:
        return false;
      case IsarType.byte:
      case IsarType.byteList:
      case IsarType.int:
      case IsarType.intList:
      case IsarType.long:
      case IsarType.longList:
        return 0;
      case IsarType.float:
      case IsarType.floatList:
      case IsarType.double:
      case IsarType.doubleList:
        return 0.0;
      case IsarType.dateTime:
      case IsarType.dateTimeList:
        return DateTime.now().microsecondsSinceEpoch;
      case IsarType.string:
      case IsarType.stringList:
        return '';
      case IsarType.object:
      case IsarType.objectList:
        return null;
    }
  }
}

extension on FilterConditionType {
  String get niceName {
    switch (this) {
      case FilterConditionType.equalTo:
        return 'is equal to';
      case FilterConditionType.greaterThan:
        return 'is greater than';
      case FilterConditionType.lessThan:
        return 'is less than';
      case FilterConditionType.between:
        return 'is between';
      case FilterConditionType.startsWith:
        return 'starts with';
      case FilterConditionType.endsWith:
        return 'ends with';
      case FilterConditionType.contains:
        return 'contains';
      case FilterConditionType.matches:
        return 'matches';
      case FilterConditionType.isNull:
        return 'is null';
      case FilterConditionType.isNotNull:
        return 'is not null';
      case FilterConditionType.elementIsNull:
        return 'element is null';
      case FilterConditionType.elementIsNotNull:
        return 'element is not null';
      case FilterConditionType.listLength:
        return 'list length between';
    }
  }

  int get valueCount {
    switch (this) {
      case FilterConditionType.isNull:
      case FilterConditionType.isNotNull:
      case FilterConditionType.elementIsNull:
      case FilterConditionType.elementIsNotNull:
        return 0;
      case FilterConditionType.equalTo:
      case FilterConditionType.greaterThan:
      case FilterConditionType.lessThan:
      case FilterConditionType.startsWith:
      case FilterConditionType.endsWith:
      case FilterConditionType.contains:
      case FilterConditionType.matches:
        return 1;
      case FilterConditionType.between:
      case FilterConditionType.listLength:
        return 2;
    }
  }
}
