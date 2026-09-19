import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/call/model/call_session.dart';

void main() {
  test('prepares the reservation and connects the returned call session', () async {
    final events = <String>[];
    final service = ImmediateCallTestService(
      _FakeCallSessionApi(events),
      _FakeCallConnection(events),
    );

    await service.start('100', accessToken: 'access-token');

    expect(events, ['prepare:100', 'connect:42:access-token']);
  });

  test('hangs up the active test call', () async {
    final connection = _FakeCallConnection([]);
    final service = ImmediateCallTestService(
      _FakeCallSessionApi([]),
      connection,
    );

    await service.hangup();

    expect(connection.hangupCount, 1);
  });
}

final class _FakeCallSessionApi implements CallSessionCommandApi {
  _FakeCallSessionApi(this.events);

  final List<String> events;

  @override
  Future<CallSession> reject(
    String callSessionId, {
    String? accessToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CallSession> prepareTestCall(
    String reservationId, {
    String? accessToken,
  }) async {
    events.add('prepare:$reservationId');
    return CallSession(
      callSessionId: '42',
      callStatus: 'PREPARING',
      callOutcome: null,
      createdAt: DateTime.utc(2026, 9, 19),
      endedAt: null,
    );
  }
}

final class _FakeCallConnection implements CallConnection {
  _FakeCallConnection(this.events);

  final List<String> events;
  int hangupCount = 0;

  @override
  Future<void> connect(String callSessionId, {String? accessToken}) async {
    events.add('connect:$callSessionId:$accessToken');
  }

  @override
  Future<void> hangup() async {
    hangupCount++;
  }
}
