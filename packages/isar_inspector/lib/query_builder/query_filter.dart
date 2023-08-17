import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/object/property_value.dart';
import 'package:isar_inspector/query_builder/query_group.dart';
import 'package:isar_inspector/util.dart';

class QueryFilter extends StatelessWidget {
  const QueryFilter({
    required this.schema,
    required this.condition,
    required this.onChanged,
    super.key,
  });

  final IsarSchema schema;
  final FilterCondition condition;
  final void Function(FilterCondition condition) onChanged;

  @override
  Widget build(BuildContext context) {
    final property = schema.getPropertyByIndex(condition.property);

    final theme = Theme.of(context);
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
                  for (final property in schema.idAndProperties)
                    if (property.type != IsarType.object &&
                        property.type != IsarType.objectList)
                      DropdownMenuItem(
                        value: property.name,
                        child: Text(property.name),
                      ),
                ],
                value: property.name,
                onChanged: (name) {
                  if (name == null) return;
                  onChanged(
                    FilterCondition(
                      type: FilterType.equalTo,
                      property: schema.getPropertyIndex(name),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            DropdownButtonHideUnderline(
              child: DropdownButton<FilterType>(
                isDense: true,
                items: [
                  for (final type in property.supportedFilters)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
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
                      value2: condition.value2,
                    ),
                  );
                },
              ),
            ),
            if (condition.type.valueCount > 0) ...[
              const SizedBox(width: 20),
              IntrinsicWidth(
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
                        value2: condition.value2,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (condition.type.valueCount == 2) ...[
              const SizedBox(width: 20),
              IntrinsicWidth(
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
                        value2: newValue,
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

enum FilterType {
  equalTo('is equal to'),
  greaterThan('is greater than'),
  lessThan('is less than'),
  between('is between', valueCount: 2),
  startsWith('starts with'),
  endsWith('ends with'),
  contains('contains'),
  matches('matches'),
  isNull('is null', valueCount: 0),
  isNotNull('is not null', valueCount: 0),
  elementIsNull('element is null', valueCount: 0),
  elementIsNotNull('element is not null', valueCount: 0);

  const FilterType(this.displayName, {this.valueCount = 1});

  final String displayName;
  final int valueCount;
}

extension on IsarPropertySchema {
  List<FilterType> get supportedFilters {
    switch (type) {
      case IsarType.bool:
      case IsarType.boolList:
        return [
          FilterType.equalTo,
          FilterType.isNull,
          FilterType.isNotNull,
          if (type == IsarType.boolList) ...[
            FilterType.elementIsNull,
            FilterType.elementIsNotNull,
          ],
        ];
      case IsarType.byte:
      case IsarType.byteList:
        return [
          FilterType.equalTo,
          FilterType.greaterThan,
          FilterType.lessThan,
          FilterType.between,
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
          FilterType.equalTo,
          FilterType.greaterThan,
          FilterType.lessThan,
          FilterType.between,
          FilterType.isNull,
          FilterType.isNotNull,
          FilterType.elementIsNull,
          FilterType.elementIsNotNull,
        ];
      case IsarType.string:
      case IsarType.stringList:
        return [
          FilterType.equalTo,
          FilterType.greaterThan,
          FilterType.lessThan,
          FilterType.between,
          FilterType.startsWith,
          FilterType.endsWith,
          FilterType.contains,
          FilterType.matches,
          FilterType.isNull,
          FilterType.isNotNull,
          if (type == IsarType.stringList) ...[
            FilterType.elementIsNull,
            FilterType.elementIsNotNull,
          ],
        ];
      case IsarType.object:
      case IsarType.objectList:
      case IsarType.json:
        return [];
    }
  }
}
