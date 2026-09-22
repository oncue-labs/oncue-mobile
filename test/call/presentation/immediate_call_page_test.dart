import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/call/application/call_connection_service.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/call/data/call_session_api_client.dart';
import 'package:oncue_mobile/call/model/call_session.dart';
import 'package:oncue_mobile/call/presentation/immediate_call_page.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/common/design_system/oncue_theme.dart';

void main() {
  testWidgets('renders the persona name at the mockup type scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildOnCueTheme(),
        home: ImmediateCallPage(
          reservationId: '1001',
          accessToken: null,
          combination: MvpCallCombinations.all.first,
          callService: ImmediateCallTestService(
            _NeverPreparingCallSessionApi(),
            _NeverConnectingCallConnection(),
          ),
        ),
      ),
    );
    await tester.pump();

    final heading = tester.widget<Text>(
      find.text(MvpCallCombinations.all.first.personaName),
    );
    expect(heading.style?.fontSize, closeTo(22.7, 0.5));
    expect(heading.style?.fontWeight, FontWeight.w800);
  });
}

final class _NeverPreparingCallSessionApi implements CallSessionCommandApi {
  @override
  Future<CallSession> prepareTestCall(
    String reservationId, {
    String? accessToken,
  }) {
    return Completer<CallSession>().future;
  }

  @override
  Future<CallSession> ringTestIncomingCall(
    String reservationId, {
    String? accessToken,
  }) {
    return Completer<CallSession>().future;
  }

  @override
  Future<CallSession> reject(String callSessionId, {String? accessToken}) {
    throw UnimplementedError();
  }
}

final class _NeverConnectingCallConnection implements CallConnection {
  @override
  Future<void> connect(String callSessionId, {String? accessToken}) {
    return Completer<void>().future;
  }

  @override
  Future<void> hangup() async {}
}
