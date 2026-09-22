import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/call/model/call_session.dart';
import 'package:oncue_mobile/common/network/api_error.dart';

void main() {
  test(
    'prepares the reservation and connects the returned call session',
    () async {
      final events = <String>[];
      final service = ImmediateCallTestService(
        _FakeCallSessionApi(events),
        _FakeCallConnection(events),
      );

      await service.start('100', accessToken: 'access-token');

      expect(events, ['prepare:100', 'connect:42:access-token']);
    },
  );

  test('hangs up the active test call', () async {
    final connection = _FakeCallConnection([]);
    final service = ImmediateCallTestService(
      _FakeCallSessionApi([]),
      connection,
    );

    await service.hangup();

    expect(connection.hangupCount, 1);
  });

  test('requests an incoming test call without directly connecting media', () async {
    final events = <String>[];
    final service = ImmediateCallTestService(
      _FakeCallSessionApi(events),
      _FakeCallConnection(events),
    );

    await service.ringIncomingCall('100', accessToken: 'access-token');

    expect(events, ['ring:100']);
  });

  test('records the incoming-call request status without logging credentials', () async {
    final diagnostics = <String>[];
    final service = ImmediateCallTestService(
      _FailingCallSessionApi(),
      _FakeCallConnection([]),
      diagnosticLogger: diagnostics.add,
    );

    await expectLater(
      service.ringIncomingCall('100', accessToken: 'access-token'),
      throwsA(isA<ApiError>()),
    );

    expect(diagnostics.last, 'immediate_incoming_call.request_failed statusCode=401');
    expect(diagnostics.join(), isNot(contains('access-token')));
  });

  test('records safe immediate-call preparation diagnostics', () async {
    final events = <String>[];
    final service = ImmediateCallTestService(
      _FakeCallSessionApi([]),
      _FakeCallConnection([]),
      diagnosticLogger: events.add,
    );

    await service.start('100', accessToken: 'access-token');

    expect(events, [
      'immediate_call.prepare_start reservationId=100',
      'immediate_call.prepare_succeeded reservationId=100 callSessionId=42',
      'immediate_call.connect_start callSessionId=42',
      'immediate_call.connect_succeeded callSessionId=42',
    ]);
    expect(events.join(), isNot(contains('access-token')));
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

  @override
  Future<CallSession> ringTestIncomingCall(
    String reservationId, {
    String? accessToken,
  }) async {
    events.add('ring:$reservationId');
    return CallSession(
      callSessionId: '42',
      callStatus: 'RINGING',
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

final class _FailingCallSessionApi implements CallSessionCommandApi {
  @override
  Future<CallSession> prepareTestCall(
    String reservationId, {
    String? accessToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CallSession> reject(String callSessionId, {String? accessToken}) {
    throw UnimplementedError();
  }

  @override
  Future<CallSession> ringTestIncomingCall(
    String reservationId, {
    String? accessToken,
  }) {
    throw const ApiError(statusCode: 401, message: 'Unauthorized');
  }
}
