import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncue_mobile/app/oncue_home_page.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/call/application/incoming_call_coordinator.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/presentation/auth_gate.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class OnCueApp extends StatefulWidget {
  const OnCueApp({
    super.key,
    this.loadReservations,
    this.reservationService,
    this.timeZoneProvider,
    this.accessToken,
    this.authService,
    this.authorizationClient,
    this.incomingCallCoordinator,
    this.immediateCallTestService,
  });

  final Future<List<Reservation>> Function()? loadReservations;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;
  final AuthService? authService;
  final OAuthAuthorizationClient? authorizationClient;
  final IncomingCallCoordinator? incomingCallCoordinator;
  final ImmediateCallTestService? immediateCallTestService;

  @override
  State<OnCueApp> createState() => _OnCueAppState();
}

final class _OnCueAppState extends State<OnCueApp> {
  @override
  void initState() {
    super.initState();
    widget.incomingCallCoordinator?.start();
  }

  @override
  void dispose() {
    unawaited(widget.incomingCallCoordinator?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = widget.authService;
    final authorizationClient = widget.authorizationClient;
    final home = authService != null && authorizationClient != null
        ? AuthGate(
            authService: authService,
            authorizationClient: authorizationClient,
            homeBuilder: (session, onLogout) =>
                _buildHome(session.accessToken, onLogout: onLogout),
          )
        : _buildHome(widget.accessToken);

    return MaterialApp(
      title: 'OnCue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: home,
    );
  }

  OnCueHomePage _buildHome(
    String? sessionAccessToken, {
    Future<void> Function()? onLogout,
  }) {
    final reservationService = widget.reservationService;
    final reservationLoader =
        widget.loadReservations ??
        (reservationService == null
            ? null
            : () => reservationService.list(accessToken: sessionAccessToken));
    return OnCueHomePage(
      loadReservations: reservationLoader,
      reservationService: reservationService,
      timeZoneProvider: widget.timeZoneProvider,
      accessToken: sessionAccessToken,
      onLogout: onLogout,
      immediateCallTestService: widget.immediateCallTestService,
    );
  }
}
