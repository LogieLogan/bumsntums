import Flutter
import UIKit
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    // Set up MLKit method channel
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let mlkitChannel = FlutterMethodChannel(name: "com.bumsntums/mlkit", binaryMessenger: controller.binaryMessenger)
    
    mlkitChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setMLKitCachingStrategy" {
        // Just acknowledge the call
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}