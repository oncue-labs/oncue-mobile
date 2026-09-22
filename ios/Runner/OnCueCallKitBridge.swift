import AVFoundation
import CallKit
import Foundation
import WebRTC

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

    // CallKit owns AVAudioSession activation. Keep WebRTC's audio device
    // module paused until CallKit calls didActivate; otherwise a cold VoIP
    // answer can create a peer connection without starting capture/playout.
    let rtcAudioSession = RTCAudioSession.sharedInstance()
    rtcAudioSession.useManualAudio = true
    rtcAudioSession.isAudioEnabled = false

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
      debugLog("answer action has no call session")
      action.fail()
      return
    }

    debugLog("answer action received callSessionId=\(callSessionId)")

    // CallKit expects this action to be fulfilled promptly. Waiting for the
    // Flutter isolate to receive and process onAnswered can make iOS end the
    // call before WebRTC starts, especially when the app is backgrounded.
    answeredCallSessionIds.insert(callSessionId)
    action.fulfill()
    debugLog("answer action fulfilled callSessionId=\(callSessionId)")
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
    debugLog("audio session activated")
    if let callSessionId = answeredCallSessionIds.first {
      audioActivatedCallSessionIds.insert(callSessionId)
      debugLog("audio activation recorded callSessionId=\(callSessionId)")
    }

    // flutter_webrtc owns the WebRTC audio engine through RTCAudioSession.
    // CallKit activates AVAudioSession outside of that owner, so forward the
    // lifecycle event explicitly; otherwise WebRTC can create a peer
    // connection without starting microphone capture or remote playback.
    let rtcAudioSession = RTCAudioSession.sharedInstance()
    rtcAudioSession.audioSessionDidActivate(audioSession)
    rtcAudioSession.isAudioEnabled = true
    if let callSessionId = answeredCallSessionIds.first {
      debugLog("audio activation event sent callSessionId=\(callSessionId)")
      eventHandler?(Self.audioActivatedEvent, callSessionId)
    }
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    debugLog("audio session deactivated")
    let rtcAudioSession = RTCAudioSession.sharedInstance()
    rtcAudioSession.audioSessionDidDeactivate(audioSession)
    rtcAudioSession.isAudioEnabled = false
  }

  private func removeCall(callSessionId: String) {
    guard let callUUID = uuidByCallSessionId.removeValue(forKey: callSessionId) else {
      return
    }
    callSessionIdByUUID.removeValue(forKey: callUUID)
    answeredCallSessionIds.remove(callSessionId)
    audioActivatedCallSessionIds.remove(callSessionId)
    appEndedCallSessionIds.remove(callSessionId)
    let rtcAudioSession = RTCAudioSession.sharedInstance()
    rtcAudioSession.isAudioEnabled = false
    rtcAudioSession.useManualAudio = false
  }

  private func debugLog(_ message: String) {
    print("[OnCue.CallKit] \(message)")
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
