// ignore_for_file: public_member_api_docs

final _word = RegExp(r'[\p{L}\p{N}\p{M}]+', unicode: true);

List<String> isarSplitWords(String input) =>
    _word.allMatches(input).map((match) => match.group(0)!).toList();
