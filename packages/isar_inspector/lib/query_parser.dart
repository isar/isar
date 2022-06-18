import 'package:isar/isar.dart';
import 'package:isar_inspector/schema.dart';
import 'package:petitparser/petitparser.dart';
import 'package:dartx/dartx.dart';

class QueryParser {
  final List<IProperty> properties;
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
          (l, _, r) => FilterGroup.and(
            [l as FilterOperation, r as FilterOperation],
          ),
        );

    builder.group().left(
          string('||').trim(),
          (l, _, r) => FilterGroup.or(
            [l as FilterOperation, r as FilterOperation],
          ),
        );

    _parser = builder.build();
  }

  FilterOperation createQueryCondition(
      String propertyName, String cmp, dynamic value) {
    final property =
        properties.where((p) => p.name == propertyName).firstOrNull;

    if (property == null) throw 'Unknown property "$propertyName"';

    switch (cmp) {
      case '!=':
      case '==':
        final filter = FilterCondition.equalTo(
          property: propertyName,
          value: value,
        );
        if (cmp == '!=') {
          return FilterGroup.not(filter);
        } else {
          return filter;
        }
      case '>':
      case '>=':
        return FilterCondition.greaterThan(
          property: propertyName,
          value: value,
          include: cmp == '>=',
        );
      case '<':
      case '<=':
        return FilterCondition.lessThan(
          property: propertyName,
          value: value,
          include: cmp == '<=',
        );
      case 'matches':
        return FilterCondition.matches(
          property: propertyName,
          wildcard: value as String,
        );
      default:
        throw 'unreachable';
    }
  }

  FilterOperation parse(String filter) {
    final result = _parser.parse(filter);
    if (result.isFailure) {
      throw result.message;
    }
    return result.value as FilterOperation;
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
      (char(r'\') & anyOf("nrtbfv\"'")).pick(1).cast();

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
      seperator = ' || ';
    }
    final joined = conditions.join(seperator);
    return '($joined)';
  }
}
