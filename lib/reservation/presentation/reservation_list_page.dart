import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_detail_page.dart';

final class ReservationListPage extends StatefulWidget {
  const ReservationListPage({
    super.key,
    required this.loadReservations,
    required this.combinations,
  });

  final Future<List<Reservation>> Function() loadReservations;
  final List<CallCombinationCard> combinations;

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

final class _ReservationListPageState extends State<ReservationListPage> {
  late Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = widget.loadReservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('예약 목록')),
      body: FutureBuilder<List<Reservation>>(
        future: _reservationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('예약을 불러오지 못했습니다.'));
          }
          final reservations = snapshot.data ?? const <Reservation>[];
          if (reservations.isEmpty) {
            return const Center(child: Text('예약된 통화가 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return _ReservationTile(
                reservation: reservation,
                combination: _findCombination(reservation),
                onTap: () => _openDetail(context, reservation),
              );
            },
          );
        },
      ),
    );
  }

  CallCombinationCard? _findCombination(Reservation reservation) {
    for (final combination in widget.combinations) {
      if (combination.personaKey == reservation.personaKey &&
          combination.scenarioKey == reservation.scenarioKey) {
        return combination;
      }
    }
    return null;
  }

  void _openDetail(BuildContext context, Reservation reservation) {
    final combination = _findCombination(reservation);
    if (combination == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReservationDetailPage(
          reservation: reservation,
          combination: combination,
        ),
      ),
    );
  }
}

final class _ReservationTile extends StatelessWidget {
  const _ReservationTile({
    required this.reservation,
    required this.combination,
    required this.onTap,
  });

  final Reservation reservation;
  final CallCombinationCard? combination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('reservation-${reservation.reservationId}'),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(combination?.personaName ?? reservation.personaKey),
        subtitle: Text(
          '${_formatScheduledAt(reservation.scheduledAtLocal)} · '
          '${_reservationStatusLabel(reservation.reservationStatus)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

String _reservationStatusLabel(String status) {
  return switch (status) {
    'SCHEDULED' => '예약됨',
    'CANCELLED' => '취소됨',
    _ => status,
  };
}

String _formatScheduledAt(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}
