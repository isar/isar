import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/query_builder/query_filter.dart';

sealed class FilterOperation {
  Filter? toIsarFilter();
}

class FilterGroup extends FilterOperation {
  FilterGroup(this.and, this.filters);

  final bool and;
  final List<FilterOperation> filters;

  @override
  Filter? toIsarFilter() {
    if (filters.isEmpty) return null;
    final isarFilters =
        filters.map((e) => e.toIsarFilter()).whereType<Filter>().toList();
    return and ? AndGroup(isarFilters) : OrGroup(isarFilters);
  }
}

class FilterCondition extends FilterOperation {
  FilterCondition({
    required this.property,
    required this.type,
    this.value1,
    this.value2,
  });

  final int property;
  final FilterType type;
  final Object? value1;
  final Object? value2;

  @override
  Filter toIsarFilter() {
    return switch (type) {
      FilterType.equalTo => EqualCondition(property: property, value: value1),
      FilterType.greaterThan =>
        GreaterCondition(property: property, value: value1),
      FilterType.lessThan => LessCondition(property: property, value: value1),
      FilterType.between =>
        BetweenCondition(property: property, lower: value1, upper: value2),
      FilterType.startsWith =>
        StartsWithCondition(property: property, value: value1! as String),
      FilterType.endsWith =>
        EndsWithCondition(property: property, value: value1! as String),
      FilterType.contains =>
        ContainsCondition(property: property, value: value1! as String),
      FilterType.matches =>
        MatchesCondition(property: property, wildcard: value1! as String),
      FilterType.isNull => IsNullCondition(property: property),
      FilterType.isNotNull => NotGroup(IsNullCondition(property: property)),
      FilterType.elementIsNull =>
        EqualCondition(property: property, value: null),
      FilterType.elementIsNotNull =>
        GreaterCondition(property: property, value: null)
    };
  }
}

class QueryGroup extends StatelessWidget {
  const QueryGroup({
    required this.schema,
    required this.group,
    required this.level,
    required this.onChanged,
    super.key,
    this.onDelete,
  });

  final IsarSchema schema;
  final FilterGroup group;
  final int level;
  final void Function(FilterGroup group) onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: level.toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Guideline(
                  group: group,
                  onChanged: onChanged,
                  onDelete: onDelete,
                ),
                const SizedBox(width: 15),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    if (group.filters.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Add a filter or nested group to limit the results.\n'
                          'Click the group type to change it.',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.5),
                          ),
                        ),
                      ),
                    for (final filter in group.filters) ...[
                      if (filter is FilterGroup)
                        QueryGroup(
                          schema: schema,
                          group: filter,
                          level: level + 1,
                          onChanged: (updated) =>
                              _performUpdate(add: updated, remove: filter),
                          onDelete: () => _performUpdate(remove: filter),
                        )
                      else
                        Row(
                          children: [
                            QueryFilter(
                              schema: schema,
                              condition: filter as FilterCondition,
                              onChanged: (updated) =>
                                  _performUpdate(add: updated, remove: filter),
                            ),
                            const SizedBox(width: 5),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => _performUpdate(remove: filter),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                    ],
                    GroupFilterButton(
                      level: level,
                      schema: schema,
                      onAdd: (newFilter) => _performUpdate(add: newFilter),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _performUpdate({FilterOperation? add, FilterOperation? remove}) {
    final newFilters = group.filters.toList();
    if (remove != null) {
      if (add != null) {
        newFilters[newFilters.indexOf(remove)] = add;
      } else {
        newFilters.remove(remove);
      }
    } else if (add != null) {
      newFilters.add(add);
    }
    onChanged(FilterGroup(group.and, newFilters));
  }
}

class _Guideline extends StatelessWidget {
  const _Guideline({
    required this.group,
    required this.onChanged,
    this.onDelete,
  });

  final FilterGroup group;
  final void Function(FilterGroup condition) onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = group.and ? Colors.orange : Colors.blue;
    return Column(
      children: [
        Expanded(
          child: Container(
            width: 17.5,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: 2.5),
                left: BorderSide(color: color, width: 2.5),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: InputChip(
            backgroundColor: color,
            deleteIconColor: Colors.white,
            label: SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  group.and ? 'AND' : 'OR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            tooltip: 'Change group type',
            onDeleted: onDelete,
            onPressed: () {
              onChanged(FilterGroup(!group.and, group.filters));
            },
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: 17.5,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: 2.5),
                left: BorderSide(color: color, width: 2.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GroupFilterButton extends StatelessWidget {
  const GroupFilterButton({
    required this.level,
    required this.schema,
    required this.onAdd,
    super.key,
  });

  final int level;
  final IsarSchema schema;
  final void Function(FilterOperation filter) onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.workspaces_rounded),
          label: const Text('Add Group'),
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(level + 1),
          ),
          onPressed: () {
            onAdd(FilterGroup(true, []));
          },
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.filter_alt_rounded),
          label: const Text('Add Filter'),
          style: ButtonStyle(
            elevation: MaterialStateProperty.all(level + 1),
          ),
          onPressed: () {
            onAdd(
              FilterCondition(
                property: schema.getPropertyIndex(schema.idName!),
                type: FilterType.isNotNull,
              ),
            );
          },
        ),
      ],
    );
  }
}
