#import "IsarFlutterPlugin.h"
#if __has_include(<isar_flutter/isar_flutter-Swift.h>)
#import <isar_flutter/isar_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "isar_flutter-Swift.h"
#endif

@implementation IsarFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIsarFlutterPlugin registerWithRegistrar:registrar];
}
@end
