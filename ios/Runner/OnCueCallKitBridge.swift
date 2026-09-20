import AVFoundation
import CallKit
import Foundation

final class OnCueCallKitBridge: NSObject, CXProviderDelegate {
  static let answeredEvent = "onAnswered"
  static let rejectedEvent = "onRejected"
  static let endedEvent = "onEnded"
  static let audioActivatedEvent = "onAudioActivated"

  private let provider: CXProvider
  private let callController: CXCallController
  private var callSessionIdByUUID: [UUID: String] = [:]
  private var uuidByCallSessionId: [String: UUID] = [:]
  private var answeredCallSessionIds: Set<String> = []
  private var audioActivatedCallSessionIds: Set<String> = []
  private var appEndedCallSessionIds: Set<String> = []

  var eventHandler: ((String, String) -> Void)?

  override init() {
    let configuration = CXProviderConfiguration(localizedName: "OnCue")
    configuration.supportsVideo = false
    configuration.maximumCallsPerCallGroup = 1
    configuration.maximumCallGroups = 1
    configuration.supportedHandleTypes = [.generic]

    provider = CXProvider(configuration: configuration)
    callController = CXCallController()

    super.init()

    provider.setDelegate(self, queue: nil)
  }

  func reportIncomingCall(
    callSessionId: String,
    displayName: String,
    callType: String,
    completion: @escaping (Error?) -> Void
  ) {
    guard !callSessionId.isEmpty, !displayName.isEmpty else {
      completion(CallKitBridgeError.invalidCallDisplayInfo)
      return
    }

    if uuidByCallSessionId[callSessionId] != nil {
      completion(nil)
      return
    }

    let callUUID = UUID()
    callSessionIdByUUID[callUUID] = callSessionId
    uuidByCallSessionId[callSessionId] = callUUID

    let update = CXCallUpdate()
    update.localizedCallerName = displayName
    update.remoteHandle = CXHandle(type: .generic, value: displayName)
    update.hasVideo = callType == "video"
    update.supportsDTMF = false
    update.supportsHolding = false

    provider.reportNewIncomingCall(with: callUUID, update: update) { [weak self] error in
      if error != nil {
        self?.removeCall(callSessionId: callSessionId)
      }
      completion(error)
    }
  }

  func endCall(
    callSessionId: String,
    completion: @escaping (Error?) -> Void
  ) {
    guard let callUUID = uuidByCallSessionId[callSessionId] else {
      completion(nil)
      return
    }

    appEndedCallSessionIds.insert(callSessionId)
    let transaction = CXTransaction(action: CXEndCallAction(call: callUUID))
    callController.request(transaction) { error in
      if error != nil {
        self.appEndedCallSessionIds.remove(callSessionId)
      }
      completion(error)
    }
  }

  func answerSucceeded(callSessionId: String) {
    // The CXAnswerCallAction is fulfilled immediately in the provider delegate.
    // Keep this method for the Flutter channel contract; it is now idempotent.
    answeredCallSessionIds.insert(callSessionId)
  }

  func answerFailed(callSessionId: String) {
    answeredCallSessionIds.remove(callSessionId)
    audioActivatedCallSessionIds.remove(callSessionId)
    removeCall(callSessionId: callSessionId)
  }

  func isAudioActivated(callSessionId: String) -> Bool {
    audioActivatedCallSessionIds.contains(callSessionId)
  }

  func providerDidReset(_ provider: CXProvider) {
    answeredCallSessionIds.removeAll()
    audioActivatedCallSessionIds.removeAll()
    appEndedCallSessionIds.removeAll()
    callSessionIdByUUID.removeAll()
    uuidByCallSessionId.removeAll()
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    guard let callSessionId = callSessionIdByUUID[action.callUUID] else {
      action.fail()
      return
    }

    // CallKit expects this action to be fulfilled promptly. Waiting for the
    // Flutter isolate to receive and process onAnswered can make iOS end the
    // call before WebRTC starts, especially when the app is backgrounded.
    answeredCallSessionIds.insert(callSessionId)
    action.fulfill()
    eventHandler?(Self.answeredEvent, callSessionId)
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    guard let callSessionId = callSessionIdByUUID[action.callUUID] else {
      action.fail()
      return
    }

    let wasAppEnded = appEndedCallSessionIds.remove(callSessionId) != nil
    let event = wasAppEnded || answeredCallSessionIds.contains(callSessionId)
      ? Self.endedEvent
      : Self.rejectedEvent
    eventHandler?(event, callSessionId)
    action.fulfill()
    removeCall(callSessionId: callSessionId)
  }

  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    if let callSessionId = answeredCallSessionIds.first {
      audioActivatedCallSessionIds.insert(callSessionId)
    }

    do {
      try audioSession.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.allowBluetooth, .defaultToSpeaker]
      )
      try audioSession.setActive(true)
      if let callSessionId = answeredCallSessionIds.first {
        eventHandler?(Self.audioActivatedEvent, callSessionId)
      }
    } catch {
      // WebRTC will surface a connection failure if the audio route cannot be activated.
    }
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    do {
      try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      // The system may already have deactivated the session.
    }
  }

  private func removeCall(callSessionId: String) {
    guard let callUUID = uuidByCallSessionId.removeValue(forKey: callSessionId) else {
      return
    }
    callSessionIdByUUID.removeValue(forKey: callUUID)
    answeredCallSessionIds.remove(callSessionId)
    audioActivatedCallSessionIds.remove(callSessionId)
    appEndedCallSessionIds.remove(callSessionId)
  }
}

private enum CallKitBridgeError: LocalizedError {
  case invalidCallDisplayInfo

  var errorDescription: String? {
    switch self {
    case .invalidCallDisplayInfo:
      return "Call session ID and display name are required."
    }
  }
}
