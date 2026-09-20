import Flutter
import AVFoundation
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private lazy var callKitBridge: OnCueCallKitBridge = {
    let bridge = OnCueCallKitBridge()
    bridge.eventHandler = { [weak self] method, callSessionId in
      self?.publishSystemCallEvent(method: method, callSessionId: callSessionId)
    }
    return bridge
  }()

  private lazy var voipPushHandler: OnCueVoIPPushHandler = {
    let handler = OnCueVoIPPushHandler(callKitBridge: callKitBridge)
    handler.onTokenUpdated = { [weak self] token in
      self?.publishPushToken(token)
    }
    return handler
  }()
  private var systemCallChannel: FlutterMethodChannel?
  private var pushDeviceChannel: FlutterMethodChannel?
  private var pendingSystemCallEvents: [(method: String, callSessionId: String)] = []
  private var pendingPushToken: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    _ = callKitBridge
    _ = voipPushHandler
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

    let systemCallChannel = FlutterMethodChannel(
      name: "oncue/system_calls",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    self.systemCallChannel = systemCallChannel
    systemCallChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleSystemCallMethod(call, result: result)
    }
    flushPendingSystemCallEvents()

    let pushDeviceChannel = FlutterMethodChannel(
      name: "oncue/push_devices",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    self.pushDeviceChannel = pushDeviceChannel
    pushDeviceChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "currentVoipPushToken" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.voipPushHandler.currentDeviceToken)
    }
    if let currentDeviceToken = voipPushHandler.currentDeviceToken {
      pendingPushToken = currentDeviceToken
    }
    flushPendingPushToken()
  }

  private func handleSystemCallMethod(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let callSessionId = arguments["callSessionId"] as? String,
      !callSessionId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(FlutterError(
        code: "INVALID_CALL_SESSION_ID",
        message: "A non-empty callSessionId is required.",
        details: nil
      ))
      return
    }

    switch call.method {
    case "presentIncomingCall":
      guard
        let displayName = arguments["displayName"] as? String,
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(FlutterError(
          code: "INVALID_CALL_DISPLAY_INFO",
          message: "A non-empty displayName is required.",
          details: nil
        ))
        return
      }

      let callType = arguments["callType"] as? String ?? "voice"
      callKitBridge.reportIncomingCall(
        callSessionId: callSessionId,
        displayName: displayName,
        callType: callType
      ) { error in
        if let error = error {
          result(FlutterError(
            code: "CALLKIT_REGISTRATION_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(nil)
        }
      }
    case "endCall":
      callKitBridge.endCall(callSessionId: callSessionId) { error in
        if let error = error {
          result(FlutterError(
            code: "CALLKIT_END_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(nil)
        }
      }
    case "answerSucceeded":
      callKitBridge.answerSucceeded(callSessionId: callSessionId)
      result(nil)
    case "answerFailed":
      callKitBridge.answerFailed(callSessionId: callSessionId)
      result(nil)
    case "isAudioActivated":
      result(callKitBridge.isAudioActivated(callSessionId: callSessionId))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func publishSystemCallEvent(method: String, callSessionId: String) {
    guard let systemCallChannel = systemCallChannel else {
      pendingSystemCallEvents.append((method: method, callSessionId: callSessionId))
      return
    }
    systemCallChannel.invokeMethod(method, arguments: callSessionId)
  }

  private func flushPendingSystemCallEvents() {
    let pendingEvents = pendingSystemCallEvents
    pendingSystemCallEvents.removeAll()
    pendingEvents.forEach { event in
      publishSystemCallEvent(method: event.method, callSessionId: event.callSessionId)
    }
  }

  private func publishPushToken(_ token: String) {
    guard let pushDeviceChannel = pushDeviceChannel else {
      pendingPushToken = token
      return
    }
    pushDeviceChannel.invokeMethod("onPushTokenUpdated", arguments: token)
  }

  private func flushPendingPushToken() {
    guard let pendingPushToken else {
      return
    }
    self.pendingPushToken = nil
    publishPushToken(pendingPushToken)
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
