import Flutter
import UIKit

public class SwiftIsarFlutterLibsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(nil)
    }
    
    public func dummyMethodToEnforceBundling() {
        // dummy calls to prevent tree shaking
        isar_get_error(0)
    }
}
