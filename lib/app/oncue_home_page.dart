import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/combination/presentation/combination_list_page.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_bottom_tab_bar.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_list_page.dart';

final class OnCueHomePage extends StatefulWidget {
  const OnCueHomePage({
    super.key,
    this.loadReservations,
    this.reservationService,
    this.timeZoneProvider,
    this.accessToken,
    this.onLogout,
    this.immediateCallTestService,
    this.callFinishedEvents,
  });

  final Future<List<Reservation>> Function()? loadReservations;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;
  final Future<void> Function()? onLogout;
  final ImmediateCallTestService? immediateCallTestService;
  final Stream<String>? callFinishedEvents;

  @override
  State<OnCueHomePage> createState() => _OnCueHomePageState();
}

final class _OnCueHomePageState extends State<OnCueHomePage> {
  int _selectedIndex = 0;
  int _reservationRefreshToken = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              CombinationListPage(
                reservationService: widget.reservationService,
                timeZoneProvider: widget.timeZoneProvider,
                accessToken: widget.accessToken,
                onLogout: widget.onLogout,
              ),
              ReservationListPage(
                key: ValueKey('reservation-list-$_reservationRefreshToken'),
                loadReservations: widget.loadReservations ?? _emptyReservations,
                combinations: MvpCallCombinations.all,
                reservationService: widget.reservationService,
                accessToken: widget.accessToken,
                onLogout: widget.onLogout,
                immediateCallTestService: widget.immediateCallTestService,
                callFinishedEvents: widget.callFinishedEvents,
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: OnCueBottomTabBar(
              key: const ValueKey('main-navigation-bar'),
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 1) {
                    _reservationRefreshToken++;
                  }
                });
              },
              items: const [
                OnCueTabItem(
                  itemKey: ValueKey('combination-tab'),
                  icon: Icons.auto_awesome,
                  label: '페르소나',
                ),
                OnCueTabItem(
                  itemKey: ValueKey('reservation-tab'),
                  icon: Icons.calendar_month,
                  label: '예약 목록',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<Reservation>> _emptyReservations() async {
  return const <Reservation>[];
}
