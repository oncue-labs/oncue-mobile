import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/model/connection_token.dart';

void main() {
  test('issues a token and starts the media connection', () async {
    final issuer = _FakeConnectionTokenIssuer();
    final transport = _FakeCallConnectionTransport();
    final service = CallConnectionService(issuer, transport);

    await service.connect('321', accessToken: 'access-token');

    expect(issuer.callSessionId, '321');
    expect(issuer.accessToken, 'access-token');
    expect(transport.connectedToken?.connectionToken, 'connection-token');
  });

  test('hangup delegates to the active media connection', () async {
    final transport = _FakeCallConnectionTransport();
    final service = CallConnectionService(
      _FakeConnectionTokenIssuer(),
      transport,
    );

    await service.connect('321');
    await service.hangup();

    expect(transport.hangupCount, 1);
  });

  test('records safe connection lifecycle diagnostics', () async {
    final events = <String>[];
    final service = CallConnectionService(
      _FakeConnectionTokenIssuer(),
      _FakeCallConnectionTransport(),
      diagnosticLogger: events.add,
    );

    await service.connect('321', accessToken: 'access-token');

    expect(events, [
      'call_connection.start callSessionId=321',
      'call_connection.token_issued callSessionId=321',
      'call_connection.connected callSessionId=321',
    ]);
    expect(events.join(), isNot(contains('connection-token')));
  });
}

final class _FakeConnectionTokenIssuer implements CallConnectionTokenIssuer {
  String? callSessionId;
  String? accessToken;

  @override
  Future<ConnectionToken> issueConnectionToken(
    String callSessionId, {
    String? accessToken,
  }) async {
    this.callSessionId = callSessionId;
    this.accessToken = accessToken;
    return ConnectionToken(
      connectionToken: 'connection-token',
      signalingUrl: 'ws://localhost/v1/signaling/call-sessions/321',
      iceServers: const [],
      expiresAt: DateTime.utc(2026, 9, 19, 12, 1),
      createdAt: DateTime.utc(2026, 9, 19, 12),
    );
  }
}

final class _FakeCallConnectionTransport implements CallConnectionTransport {
  ConnectionToken? connectedToken;
  int hangupCount = 0;

  @override
  Future<void> connect(ConnectionToken token) async {
    connectedToken = token;
  }

  @override
  Future<void> hangup() async {
    hangupCount++;
  }
}
