import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/combination/presentation/combination_list_page.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_list_page.dart';

final class OnCueHomePage extends StatefulWidget {
  const OnCueHomePage({
    super.key,
    this.loadReservations,
    this.reservationService,
    this.accessToken,
  });

  final Future<List<Reservation>> Function()? loadReservations;
  final ReservationService? reservationService;
  final String? accessToken;

  @override
  State<OnCueHomePage> createState() => _OnCueHomePageState();
}

final class _OnCueHomePageState extends State<OnCueHomePage> {
  late final List<Widget> _pages;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CombinationListPage(),
      ReservationListPage(
        loadReservations: widget.loadReservations ?? _emptyReservations,
        combinations: MvpCallCombinations.all,
        reservationService: widget.reservationService,
        accessToken: widget.accessToken,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('main-navigation-bar'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            key: ValueKey('combination-tab'),
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '통화 조합',
          ),
          NavigationDestination(
            key: ValueKey('reservation-tab'),
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: '예약 목록',
          ),
        ],
      ),
    );
  }
}

Future<List<Reservation>> _emptyReservations() async {
  return const <Reservation>[];
}
