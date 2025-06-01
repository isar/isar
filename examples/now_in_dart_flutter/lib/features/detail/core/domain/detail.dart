import 'package:equatable/equatable.dart';

class Detail extends Equatable {
  const Detail({required this.html});

  final String html;

  /// An empty detail used to represent null detail.

  // This pattern helps us to work with concrete domain level entities and
  // avoid nulls.
  static const empty = Detail(html: '');

  /// Convenience getter to determine whether the current detail is empty.
  bool get isEmpty => this == Detail.empty;

  @override
  List<Object?> get props => [html];
}
