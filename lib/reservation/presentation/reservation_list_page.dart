import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/common/network/api_error.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_detail_page.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_form_page.dart';

final class ReservationListPage extends StatefulWidget {
  const ReservationListPage({
    super.key,
    required this.loadReservations,
    required this.combinations,
    this.reservationService,
    this.accessToken,
  });

  final Future<List<Reservation>> Function() loadReservations;
  final List<CallCombinationCard> combinations;
  final ReservationService? reservationService;
  final String? accessToken;

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

  Future<void> _openDetail(
    BuildContext context,
    Reservation reservation,
  ) async {
    final combination = _findCombination(reservation);
    if (combination == null) {
      return;
    }
    final updatedReservation = await Navigator.of(context).push<Reservation>(
      MaterialPageRoute<Reservation>(
        builder: (_) => ReservationDetailPage(
          reservation: reservation,
          combination: combination,
          onEdit: widget.reservationService == null
              ? null
              : () => _openEditForm(context, reservation, combination),
          onCancel: widget.reservationService == null
              ? null
              : () => _cancelReservation(context, reservation),
        ),
      ),
    );
    if (updatedReservation == null || !context.mounted) {
      return;
    }
    setState(() {
      _reservationsFuture = widget.loadReservations();
    });
  }

  Future<void> _openEditForm(
    BuildContext context,
    Reservation reservation,
    CallCombinationCard combination,
  ) async {
    final service = widget.reservationService;
    if (service == null) {
      return;
    }
    final updatedReservation = await Navigator.of(context).push<Reservation>(
      MaterialPageRoute<Reservation>(
        builder: (_) => ReservationFormPage(
          combination: combination,
          reservationId: reservation.reservationId,
          initialScenarioContext: reservation.scenarioContext ?? '',
          initialCallGoal: reservation.callGoal ?? '',
          initialScheduledAtLocal: reservation.scheduledAtLocal,
          timeZone: reservation.timeZone,
          reservationService: service,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (updatedReservation == null || !context.mounted) {
      return;
    }
    Navigator.of(context).pop(updatedReservation);
  }

  Future<void> _cancelReservation(
    BuildContext context,
    Reservation reservation,
  ) async {
    final service = widget.reservationService;
    if (service == null) {
      return;
    }
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('예약을 취소할까요?'),
        content: const Text('취소한 예약은 다시 사용할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('돌아가기'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );
    if (shouldCancel != true || !context.mounted) {
      return;
    }
    try {
      final cancelledReservation = await service.cancel(
        reservation.reservationId,
        accessToken: widget.accessToken,
      );
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(cancelledReservation);
    } on ApiError catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
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
        leading: _PersonaImage(assetPath: combination?.personaImageAsset),
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

final class _PersonaImage extends StatelessWidget {
  const _PersonaImage({required this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFE8EAF6),
            child: Icon(Icons.person),
          ),
        ),
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
