## Isar tests

Use the following commands to run the tests on a connected device:

### Unit tests

```
sh tool/prepare_tests.sh
sh tool/build_debug.sh
dart test
```

### Integration tests

```
sh tool/prepare_tests.sh
sh tool/build_debug.sh
flutter test integration_test/integration_test.dart
```
