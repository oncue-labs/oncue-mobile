import 'package:flutter/material.dart';
import 'package:oncue_mobile/app/oncue_home_page.dart';
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
  });

  final Future<List<Reservation>> Function()? loadReservations;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnCue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: OnCueHomePage(
        loadReservations: loadReservations,
        reservationService: reservationService,
        timeZoneProvider: timeZoneProvider,
        accessToken: accessToken,
      ),
    );
  }
}
