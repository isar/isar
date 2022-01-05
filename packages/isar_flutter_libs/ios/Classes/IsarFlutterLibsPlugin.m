#import "IsarFlutterLibsPlugin.h"
#if __has_include(<isar_flutter_libs/isar_flutter_libs-Swift.h>)
#import <isar_flutter_libs/isar_flutter_libs-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "isar_flutter_libs-Swift.h"
#endif

@implementation IsarFlutterLibsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIsarFlutterLibsPlugin registerWithRegistrar:registrar];
}
@end
