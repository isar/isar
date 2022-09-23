part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.index = 0,
  });

  final int index;

  @override
  List<Object> get props => [index];
}
