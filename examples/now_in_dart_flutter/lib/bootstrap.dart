import 'dart:async';
import 'dart:developer' as dev show log;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:now_in_dart_flutter/app/app_bloc_observer.dart';
import 'package:now_in_dart_flutter/features/core/data/data.dart';

typedef _BootstrapBuilder = Widget Function(Dio dio);

void bootstrap(_BootstrapBuilder builder) {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = AppBlocObserver();

  FlutterError.onError = (details) {
    dev.log(
      details.exceptionAsString(),
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () async {
      await IsarDatabase().init();
      final dio = Dio()
        ..options = BaseOptions(
          baseUrl: 'api.github.com',
          headers: {'Accept': 'application/vnd.github.html+json'},
          responseType: ResponseType.plain,
          validateStatus: (status) {
            return status != null && status >= 200 && status < 400;
          },
        );
      runApp(builder(dio));
    },
    (error, stackTrace) => dev.log(
      error.toString(),
      stackTrace: stackTrace,
    ),
  );
}
