import Foundation
import PushKit

final class OnCueVoIPPushHandler: NSObject, PKPushRegistryDelegate {
  private let callKitBridge: OnCueCallKitBridge
  private let pushRegistry: PKPushRegistry

  init(callKitBridge: OnCueCallKitBridge) {
    self.callKitBridge = callKitBridge
    pushRegistry = PKPushRegistry(queue: .main)

    super.init()

    pushRegistry.delegate = self
    pushRegistry.desiredPushTypes = [.voIP]
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    // Device token registration is added with the push-device API.
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    // The backend device-token deletion API is added with device registration.
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

    let payload = payload.dictionaryPayload
    guard
      let callSessionId = Self.stringValue(payload["callSessionId"]),
      let displayName = Self.stringValue(payload["displayName"])
    else {
      completion()
      return
    }

    callKitBridge.reportIncomingCall(
      callSessionId: callSessionId,
      displayName: displayName,
      callType: Self.stringValue(payload["callType"]) ?? "voice",
      completion: { _ in completion() }
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
}
