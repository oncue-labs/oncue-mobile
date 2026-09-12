import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/model/call_session.dart';

void main() {
  test('maps the confirmed reject response into a call session', () {
    final session = CallSession.fromJson({
      'callSessionId': 'call-session-123',
      'callStatus': 'RINGING',
      'callOutcome': 'FAILED',
      'createdAt': '2026-09-12T10:00:00Z',
      'endedAt': '2026-09-12T10:00:05Z',
    });

    expect(session.callSessionId, 'call-session-123');
    expect(session.callStatus, 'RINGING');
    expect(session.callOutcome, 'FAILED');
    expect(session.createdAt, DateTime.parse('2026-09-12T10:00:00Z'));
    expect(session.endedAt, DateTime.parse('2026-09-12T10:00:05Z'));
  });
}
