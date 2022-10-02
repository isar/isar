## Isar tests

Use the following commands to run the tests on a connected device:

### Unit tests

```
sh tool/setup_tests.sh
dart test
```

### Integration tests

```
flutter drive --driver=isar_driver.dart --target=isar_driver_target.dart
```
