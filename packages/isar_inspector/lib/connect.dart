import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/schema.dart';
import 'package:isar_inspector/service.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:provider/provider.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({Key? key}) : super(key: key);

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _uriController = TextEditingController();
  // ignore: unused_field
  String _message = '';

  Future<void> _connect() async {
    try {
      final service = await Service.connect(_uriController.text);
      final instances = await service.listInstances();
      final schemaJson = await service.getSchema();
      final collections = schemaJson.map((e) {
        final json = e as Map<String, dynamic>;
        return Collection.fromJson(json);
      }).toList();

      final provider = Provider.of<AppState>(context, listen: false);
      provider.service = service;
      provider.instances = instances;
      provider.collections = collections;

      service.onDone.then((value) {
        provider.service = null;
      });

      print('Connected to service $service');
    } catch (e, st) {
      print('ERROR: Unable to connect to VMService');
      print(e);
      print(st);
      setState(() {
        _message = "Can't connect to this VMService: $e";
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: IsarCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Connect to Isar',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 12),
                const Text('Paste the URL to the Isar instance.'),
                const SizedBox(height: 15),
                TextField(
                  controller: _uriController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ws://127.0.0.1:41000/auth-code/',
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _connect,
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
