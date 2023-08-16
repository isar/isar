import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar_inspector/connect_client.dart';
import 'package:isar_inspector/connected_layout.dart';
import 'package:isar_inspector/error_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({
    required this.port,
    required this.secret,
    super.key,
  });

  final String port;
  final String secret;

  @override
  State<ConnectionScreen> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionScreen> {
  late Future<ConnectClient> clientFuture;

  @override
  void initState() {
    clientFuture = ConnectClient.connect(widget.port, widget.secret);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ConnectionScreen oldWidget) {
    if (oldWidget.port != widget.port || oldWidget.secret != widget.secret) {
      clientFuture = ConnectClient.connect(widget.port, widget.secret);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectClient>(
      future: clientFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _InstancesLoader(client: snapshot.data!);
        } else if (snapshot.hasError) {
          return const ErrorScreen();
        } else {
          return const Loading();
        }
      },
    );
  }
}

class _InstancesLoader extends StatefulWidget {
  const _InstancesLoader({required this.client});

  final ConnectClient client;

  @override
  State<_InstancesLoader> createState() => _InstancesLoaderState();
}

class _InstancesLoaderState extends State<_InstancesLoader> {
  late Future<List<String>> instancesFuture;
  late StreamSubscription<void> _instancesSubscription;

  @override
  void initState() {
    instancesFuture = widget.client.listInstances();
    _instancesSubscription = widget.client.instancesChanged.listen((event) {
      setState(() {
        instancesFuture = widget.client.listInstances();
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _InstancesLoader oldWidget) {
    instancesFuture = widget.client.listInstances();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _instancesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: instancesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ConnectedLayout(
            client: widget.client,
            instances: snapshot.data!,
          );
        } else if (snapshot.hasError) {
          return const ErrorScreen();
        } else {
          return const Loading();
        }
      },
    );
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
