import 'package:isar/isar.dart';
import 'package:child_package1/child_package1.dart';
import 'package:child_package2/child_package2.dart';

@ExternalCollection(ChildModel1)
@ExternalCollection(ChildModel2)
@ExternalCollection(ChildModel3)
@ExternalCollection(ChildModel4)
class SomeClass {}
