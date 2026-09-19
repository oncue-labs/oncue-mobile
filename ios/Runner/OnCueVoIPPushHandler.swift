import Foundation
import PushKit

final class OnCueVoIPPushHandler: NSObject, PKPushRegistryDelegate {
  private let callKitBridge: OnCueCallKitBridge
  private let pushRegistry: PKPushRegistry
  private(set) var currentDeviceToken: String?
  var onTokenUpdated: ((String) -> Void)?

  init(callKitBridge: OnCueCallKitBridge) {
    self.callKitBridge = callKitBridge
    pushRegistry = PKPushRegistry(queue: .main)

    super.init()

    pushRegistry.delegate = self
    pushRegistry.desiredPushTypes = [.voIP]
    debugLog("VoIP push registry configured")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else {
      return
    }
    let deviceToken = pushCredentials.token
      .map { String(format: "%02x", $0) }
      .joined()
    guard !deviceToken.isEmpty else {
      return
    }
    currentDeviceToken = deviceToken
    debugLog("VoIP push token received")
    onTokenUpdated?(deviceToken)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    guard type == .voIP else {
      return
    }
    currentDeviceToken = nil
    debugLog("VoIP push token invalidated")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    debugLog("VoIP push received")
    let payload = payload.dictionaryPayload
    guard
      let callSessionId = Self.stringValue(payload["callSessionId"]),
      let displayName = Self.stringValue(payload["displayName"])
    else {
      completion()
      return
    }

    debugLog("Reporting incoming call to CallKit")
    callKitBridge.reportIncomingCall(
      callSessionId: callSessionId,
      displayName: displayName,
      callType: Self.stringValue(payload["callType"]) ?? "voice",
      completion: { error in
        self.debugLog(error == nil ? "CallKit incoming call reported" : "CallKit incoming call failed")
        completion()
      }
    )
  }

  private static func stringValue(_ value: Any?) -> String? {
    if let value = value as? String {
      let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
      return normalizedValue.isEmpty ? nil : normalizedValue
    }
    if let value = value as? NSNumber {
      return value.stringValue
    }
    return nil
  }

  private func debugLog(_ message: String) {
    #if DEBUG
    print("[PushKit] \(message)")
    #endif
  }
}
