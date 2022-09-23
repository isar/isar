import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_repository.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_repository.dart';
import 'package:now_in_dart_flutter/features/home/home.dart';

class App extends StatelessWidget {
  const App({
    required DartDetailRepository dartDetailRepository,
    required FlutterDetailRepository flutterDetailRepository,
    super.key,
  })  : _dartDetailRepository = dartDetailRepository,
        _flutterDetailRepository = flutterDetailRepository;

  final DartDetailRepository _dartDetailRepository;
  final FlutterDetailRepository _flutterDetailRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _dartDetailRepository),
        RepositoryProvider.value(value: _flutterDetailRepository),
      ],
      child: MaterialApp(
        darkTheme: ThemeData.dark(),
        home: const HomePage(),
      ),
    );
  }
}
