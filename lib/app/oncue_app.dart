import 'package:flutter/material.dart';
import 'package:oncue_mobile/app/oncue_home_page.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/auth/data/oauth_authorization_client.dart';
import 'package:oncue_mobile/auth/presentation/auth_gate.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class OnCueApp extends StatelessWidget {
  const OnCueApp({
    super.key,
    this.loadReservations,
    this.reservationService,
    this.timeZoneProvider,
    this.accessToken,
    this.authService,
    this.authorizationClient,
  });

  final Future<List<Reservation>> Function()? loadReservations;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;
  final AuthService? authService;
  final OAuthAuthorizationClient? authorizationClient;

  @override
  Widget build(BuildContext context) {
    final authService = this.authService;
    final authorizationClient = this.authorizationClient;
    final home = authService != null && authorizationClient != null
        ? AuthGate(
            authService: authService,
            authorizationClient: authorizationClient,
            homeBuilder: (session) => _buildHome(session.accessToken),
          )
        : _buildHome(accessToken);

    return MaterialApp(
      title: 'OnCue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: home,
    );
  }

  OnCueHomePage _buildHome(String? sessionAccessToken) {
    return OnCueHomePage(
      loadReservations: loadReservations,
      reservationService: reservationService,
      timeZoneProvider: timeZoneProvider,
      accessToken: sessionAccessToken,
    );
  }
}
