import Flutter
import AVFoundation
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

    let callPermissionChannel = FlutterMethodChannel(
      name: "oncue/call_permissions",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    callPermissionChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "checkRequiredPermissions":
        result(Self.callPermissionStatus())
      case "requestMissingPermissions":
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
          DispatchQueue.main.async {
            result(granted ? "ready" : "permissionRequired")
          }
        }
      case "openSettings":
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
          result(FlutterError(
            code: "SETTINGS_UNAVAILABLE",
            message: "The application settings URL is unavailable.",
            details: nil
          ))
          return
        }
        UIApplication.shared.open(settingsUrl) { _ in
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func callPermissionStatus() -> String {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
      return "ready"
    case .denied, .undetermined:
      return "permissionRequired"
    @unknown default:
      return "permissionRequired"
    }
  }
}
