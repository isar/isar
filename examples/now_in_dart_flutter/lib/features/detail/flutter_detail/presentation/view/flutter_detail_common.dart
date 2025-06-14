import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:now_in_dart_flutter/features/core/presentattion/no_connection_toast.dart';
import 'package:now_in_dart_flutter/features/core/presentattion/no_results_display.dart';
import 'package:now_in_dart_flutter/features/detail/core/presentation/widget/detail_webview.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/application/flutter_detail_bloc.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_repository.dart';

class FlutterDetailCommonPage extends StatelessWidget {
  const FlutterDetailCommonPage({
    required FlutterDetailEvent event,
    super.key,
  }) : _event = event;

  final FlutterDetailEvent _event;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return FlutterDetailBloc(
          repository: context.read<FlutterDetailRepository>(),
        )..add(_event);
      },
      child: const FlutterDetailCommonView(),
    );
  }
}

class FlutterDetailCommonView extends StatefulWidget {
  const FlutterDetailCommonView({super.key});

  @override
  State<FlutterDetailCommonView> createState() =>
      _FlutterDetailCommonViewState();
}

class _FlutterDetailCommonViewState extends State<FlutterDetailCommonView> {
  bool _hasAlreadyShownNoConnectionToast = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlutterDetailBloc, FlutterDetailState>(
      listener: (context, state) {
        if (!state.detail.isFresh! && !_hasAlreadyShownNoConnectionToast) {
          _hasAlreadyShownNoConnectionToast = true;
          showNoConnectionToast('No Internet Connection!!!', context);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case FlutterDetailStatus.initial:
            return const SizedBox.shrink();

          case FlutterDetailStatus.loading:
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );

          case FlutterDetailStatus.success:
            final receivedDetail = state.detail;
            if (receivedDetail.entity!.isEmpty) {
              return const NoResultsDisplay(
                message: "Sorry. There's nothing to display ☹️",
              );
            }
            return DetailWebView(html: receivedDetail.entity!.html);

          case FlutterDetailStatus.failure:
            return NoResultsDisplay(message: state.failureMessage!);
        }
      },
    );
  }
}
