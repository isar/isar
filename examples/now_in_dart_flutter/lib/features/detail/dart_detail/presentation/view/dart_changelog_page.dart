import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:now_in_dart_flutter/features/core/data/id.dart';
import 'package:now_in_dart_flutter/features/core/presentattion/no_connection_toast.dart';
import 'package:now_in_dart_flutter/features/core/presentattion/no_results_display.dart';
import 'package:now_in_dart_flutter/features/detail/core/presentation/widget/detail_webview.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/application/dart_detail_bloc.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_repository.dart';

class DartChangelogPage extends StatelessWidget {
  const DartChangelogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dart')),
      body: BlocProvider(
        create: (context) {
          const id = EntityId.dartChangelogDetail;
          return DartDetailBloc(
            repository: context.read<DartDetailRepository>(),
          )..add(const DartDetailEvent.dartChangelogDetailRequested(id));
        },
        child: const DartChangelogView(),
      ),
    );
  }
}

class DartChangelogView extends StatefulWidget {
  const DartChangelogView({super.key});

  @override
  State<DartChangelogView> createState() => _DartChangelogViewState();
}

class _DartChangelogViewState extends State<DartChangelogView> {
  bool _hasAlreadyShownNoConnectionToast = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DartDetailBloc, DartDetailState>(
      listener: (context, state) {
        if (!state.detail.isFresh! && !_hasAlreadyShownNoConnectionToast) {
          _hasAlreadyShownNoConnectionToast = true;
          showNoConnectionToast('No Internet Connection!!!', context);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case DartDetailStatus.initial:
            return const SizedBox.shrink();

          case DartDetailStatus.loading:
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );

          case DartDetailStatus.success:
            final receivedDetail = state.detail;
            if (receivedDetail.entity!.isEmpty) {
              return const NoResultsDisplay(
                message: "Sorry. There's nothing to display ☹️",
              );
            }
            return DetailWebView(
              html: receivedDetail.entity!.html,
            );

          case DartDetailStatus.failure:
            return NoResultsDisplay(message: state.failureMessage!);
        }
      },
    );
  }
}
