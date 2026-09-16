import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let timeZoneChannel = FlutterMethodChannel(
      name: "oncue/device_time_zone",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    timeZoneChannel.setMethodCallHandler { call, result in
      guard call.method == "currentTimeZone" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(TimeZone.current.identifier)
    }
  }
}
