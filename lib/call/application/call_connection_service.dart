import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:oncue_mobile/call/model/connection_token.dart';

abstract interface class CallConnectionTokenIssuer {
  Future<ConnectionToken> issueConnectionToken(
    String callSessionId, {
    String? accessToken,
  });
}

abstract interface class CallConnectionTransport {
  Future<void> connect(ConnectionToken token);

  Future<void> hangup();
}

abstract interface class CallConnection {
  Future<void> connect(String callSessionId, {String? accessToken});

  Future<void> hangup();
}

/// Coordinates token issuance and the platform-specific media connection.
///
/// The token issuer is kept separate from the transport so the business flow
/// can be tested without creating native WebRTC objects. Android can reuse this
/// contract later with a platform-specific transport implementation.
final class CallConnectionService implements CallConnection {
  CallConnectionService(this._tokenIssuer, this._transport);

  final CallConnectionTokenIssuer _tokenIssuer;
  final CallConnectionTransport _transport;
  bool _isActive = false;

  @override
  Future<void> connect(String callSessionId, {String? accessToken}) async {
    if (_isActive) {
      await hangup();
    }

    final token = await _tokenIssuer.issueConnectionToken(
      callSessionId,
      accessToken: accessToken,
    );
    try {
      await _transport.connect(token);
      _isActive = true;
    } catch (_) {
      await _transport.hangup();
      rethrow;
    }
  }

  @override
  Future<void> hangup() async {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    await _transport.hangup();
  }
}

/// Production iOS/Android transport using WebRTC media and WebSocket
/// signaling. WebSocket carries only signaling messages; microphone and
/// remote audio travel through the WebRTC peer connection.
final class FlutterWebRtcCallConnectionTransport
    implements CallConnectionTransport {
  FlutterWebRtcCallConnectionTransport({
    this.connectionTimeout = const Duration(seconds: 30),
  });

  final Duration connectionTimeout;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  WebSocket? _signalingSocket;
  StreamSubscription<Object?>? _signalingSubscription;
  Completer<void>? _connectionCompleter;
  bool _isConnected = false;

  @override
  Future<void> connect(ConnectionToken token) async {
    await hangup();
    final connectionCompleter = Completer<void>();
    _connectionCompleter = connectionCompleter;

    try {
      final peerConnection = await createPeerConnection(
        _peerConfiguration(token),
      );
      _peerConnection = peerConnection;
      _configurePeerConnection(peerConnection);

      _signalingSocket = await WebSocket.connect(
        token.signalingUrl,
        headers: {'Authorization': 'Bearer ${token.connectionToken}'},
      );
      _signalingSubscription = _signalingSocket!.listen(
        (message) => unawaited(_handleSignalingMessage(message)),
        onError: (Object error, StackTrace stackTrace) {
          _completeConnectionError(error, stackTrace);
        },
        onDone: () {
          if (!_isConnected) {
            _completeConnectionError(
              StateError(
                'The signaling socket closed before WebRTC connected.',
              ),
              StackTrace.current,
            );
          }
        },
      );

      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localStream!.getAudioTracks()) {
        await peerConnection.addTrack(track, _localStream!);
      }

      final offer = await peerConnection.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      await peerConnection.setLocalDescription(offer);
      _sendSignalingMessage({
        'type': 'offer',
        'payload': {'sdp': offer.sdp},
      });

      await connectionCompleter.future.timeout(connectionTimeout);
    } catch (_) {
      await hangup();
      rethrow;
    } finally {
      if (identical(_connectionCompleter, connectionCompleter)) {
        _connectionCompleter = null;
      }
    }
  }

  @override
  Future<void> hangup() async {
    final socket = _signalingSocket;
    _signalingSocket = null;
    if (socket != null) {
      try {
        if (socket.readyState == WebSocket.open) {
          socket.add(jsonEncode({'type': 'hangup'}));
        }
      } catch (_) {
        // The peer may already have closed the socket.
      }
    }

    await _signalingSubscription?.cancel();
    _signalingSubscription = null;
    await socket?.close();

    final peerConnection = _peerConnection;
    _peerConnection = null;
    if (peerConnection != null) {
      await peerConnection.close();
      await peerConnection.dispose();
    }

    final localStream = _localStream;
    _localStream = null;
    for (final track
        in localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }

    _isConnected = false;
  }

  Map<String, dynamic> _peerConfiguration(ConnectionToken token) {
    return {
      'iceServers': [
        for (final server in token.iceServers)
          {
            'urls': server.urls,
            if (server.username != null) 'username': server.username,
            if (server.credential != null) 'credential': server.credential,
          },
      ],
    };
  }

  void _configurePeerConnection(RTCPeerConnection peerConnection) {
    peerConnection.onIceCandidate = (candidate) {
      final candidateValue = candidate.candidate;
      if (candidateValue == null || candidateValue.trim().isEmpty) {
        return;
      }
      _sendSignalingMessage({
        'type': 'ice-candidate',
        'payload': {
          'candidate': candidateValue,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    peerConnection.onConnectionState = (state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _isConnected = true;
          _connectionCompleter?.complete();
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _completeConnectionError(
            StateError('WebRTC connection failed: $state'),
            StackTrace.current,
          );
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          break;
      }
    };
    peerConnection.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _isConnected = true;
        _connectionCompleter?.complete();
      }
    };
  }

  Future<void> _handleSignalingMessage(Object? message) async {
    if (message is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final type = decoded['type'];
      final payload = decoded['payload'];
      if (type == 'answer' && payload is Map<String, dynamic>) {
        final sdp = payload['sdp'];
        if (sdp is String && sdp.trim().isNotEmpty) {
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(sdp, 'answer'),
          );
        }
      }
    } catch (error, stackTrace) {
      _completeConnectionError(error, stackTrace);
    }
  }

  void _sendSignalingMessage(Map<String, dynamic> message) {
    final socket = _signalingSocket;
    if (socket == null || socket.readyState != WebSocket.open) {
      return;
    }
    socket.add(jsonEncode(message));
  }

  void _completeConnectionError(Object error, StackTrace stackTrace) {
    final completer = _connectionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }
}
