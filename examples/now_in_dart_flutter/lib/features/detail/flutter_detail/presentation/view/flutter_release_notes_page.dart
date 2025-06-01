import 'package:flutter/material.dart';
import 'package:now_in_dart_flutter/features/core/data/id.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/application/flutter_detail_bloc.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/presentation/view/flutter_detail_common.dart';

class FlutterReleaseNotesPage extends StatefulWidget {
  const FlutterReleaseNotesPage({super.key});

  @override
  State<FlutterReleaseNotesPage> createState() =>
      _FlutterReleaseNotesPageState();
}

class _FlutterReleaseNotesPageState extends State<FlutterReleaseNotesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const FlutterDetailCommonPage(
      event: FlutterDetailEvent.flutterReleaseNotesDetailRequested(
        EntityId.flutterReleaseNotesDetail,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
