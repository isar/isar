import 'package:isar_inspector/schema.dart';
import 'package:petitparser/petitparser.dart';
import 'package:isar/src/query_builder.dart';
import 'package:dartx/dartx.dart';

class QueryParser {
  final List<Property> properties;
  late final Parser _parser;

  QueryParser(this.properties) {
    final builder = ExpressionBuilder();
    builder.group().primitive(QueryGrammar.condition, (List condition) {
      final property = condition[0] as String;
      final cmp = condition[1] as String;
      final value = condition[2];
      return createQueryCondition(property, cmp, value);
    });

    builder.group().wrapper(
          char('(').trim(),
          char(')').trim(),
          (left, value, right) => value,
        );

    builder.group().left(
          string('&&').trim(),
          (l, _, r) => FilterGroup(
            conditions: [l as QueryOperation, r as QueryOperation],
            groupType: FilterGroupType.And,
          ),
        );

    builder.group().left(
          string('||').trim(),
          (l, _, r) => FilterGroup(
            conditions: [l as QueryOperation, r as QueryOperation],
            groupType: FilterGroupType.Or,
          ),
        );

    _parser = builder.build();
  }

  FilterGroup flatten(FilterGroup group) {
    if (group.groupType == FilterGroupType.Not) return group;
    final newConditions = <QueryOperation>[];
    for (var condition in group.conditions) {
      if (condition is FilterGroup) {
        final flatCondition = flatten(condition);
        if (condition.groupType == flatCondition.groupType &&
            condition.groupType != FilterGroupType.Not) {
          newConditions.addAll(flatCondition.conditions);
        } else {
          newConditions.add(flatCondition);
        }
      } else {
        newConditions.add(condition);
      }
    }
    return FilterGroup(
      conditions: newConditions,
      groupType: group.groupType,
    );
  }

  QueryOperation createQueryCondition(
      String propertyName, String cmp, dynamic value) {
    final property =
        properties.where((p) => p.name == propertyName).firstOrNull;

    if (property == null) throw 'Unknown property "$propertyName"';

    final propertyIndex = properties.indexOf(property);
    switch (cmp) {
      case '!=':
      case '==':
        final condition = QueryCondition(
          ConditionType.Eq,
          propertyIndex,
          property.typeName,
          lower: value,
          includeLower: true,
          upper: value,
          includeUpper: true,
        );
        if (cmp == '!=') {
          return FilterGroup(
            conditions: [condition],
            groupType: FilterGroupType.Not,
          );
        } else {
          return condition;
        }
      case '>':
      case '>=':
        return QueryCondition(
          ConditionType.Gt,
          propertyIndex,
          property.typeName,
          lower: value,
          includeLower: cmp == '>=',
        );
      case '<':
      case '<=':
        return QueryCondition(
          ConditionType.Lt,
          propertyIndex,
          property.typeName,
          upper: value,
          includeUpper: cmp == '<=',
        );
      case 'matches':
        return QueryCondition(
          ConditionType.Matches,
          propertyIndex,
          property.typeName,
          lower: value,
        );
      default:
        throw 'unreachable';
    }
  }

  QueryOperation parse(String filter) {
    final result = _parser.parse(filter);
    if (result.isFailure) {
      throw result.message;
    }
    return result.value as QueryOperation;
  }
}

class QueryGrammar {
  static Parser get cmpOperator => (string('==') |
      string('!=') |
      string('>') |
      string('>=') |
      string('<') |
      string('<=') |
      'matches'.toParser(caseInsensitive: true).map((_) => 'matches'));

  static Parser get boolToken =>
      (string('true') | string('false')).map((value) => value == 'true');

  static Parser<num> get numberToken => ((digit() | char('.')).and() &
              (digit().star() &
                  ((char('.') & digit().plus()) |
                          (char('x') & digit().plus()) |
                          (anyOf('Ee') &
                              anyOf('+-').optional() &
                              digit().plus()))
                      .optional()))
          .flatten()
          .map((v) {
        return num.parse(v);
      });

  static String unescape(String v) => v.replaceAllMapped(
      RegExp("\\\\[nrtbf\"']"),
      (v) => const {
            'n': '\n',
            'r': '\r',
            't': '\t',
            'b': '\b',
            'f': '\f',
            'v': '\v',
            "'": "'",
            '"': '"'
          }[v.group(0)!.substring(1)]!);

  static Parser<String> get escapedChar =>
      (char(r'\') & anyOf("nrtbfv\"'")).pick(1);

  static Parser<String> get sqStringToken => (char("'") &
          (anyOf(r"'\").neg() | escapedChar).star().flatten() &
          char("'"))
      .pick(1)
      .map((v) => unescape(v as String));

  static Parser<String> get dqStringToke => (char('"') &
          (anyOf(r'"\').neg() | escapedChar).star().flatten() &
          char('"'))
      .pick(1)
      .map((v) => unescape(v as String));

  static Parser<String> get stringToken =>
      sqStringToken.or(dqStringToke).cast();

  static Parser get valueToken => boolToken | numberToken | stringToken;

  static Parser get identifier =>
      (letter() | digit()).plus().map((chars) => chars.join());

  static Parser<List> get condition =>
      identifier.trim() & cmpOperator.trim() & valueToken.trim();
}

class AndOr {
  final List<dynamic> conditions;
  final bool and;

  AndOr(this.conditions, this.and);

  AndOr flatten() {
    final newConditions = [];
    for (var condition in conditions) {
      if (condition is AndOr) {
        final flatCondition = condition.flatten();
        if (flatCondition.and == and) {
          newConditions.addAll(flatCondition.conditions);
        } else {
          newConditions.add(flatCondition);
        }
      } else {
        newConditions.add(condition);
      }
    }
    return AndOr(newConditions, and);
  }

  @override
  String toString() {
    String seperator;
    if (and) {
      seperator = ' && ';
    } else {
      seperator = ' || ';
    }
    final joined = conditions.join(seperator);
    return '($joined)';
  }
}
