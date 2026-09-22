import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_avatar.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_card.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_snackbar.dart';
import 'package:oncue_mobile/common/design_system/widgets/confirm_dialog.dart';
import 'package:oncue_mobile/common/design_system/widgets/empty_state.dart';
import 'package:oncue_mobile/common/design_system/widgets/header_banner.dart';
import 'package:oncue_mobile/common/design_system/widgets/icon_badge.dart';
import 'package:oncue_mobile/common/design_system/widgets/status_chip.dart';
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
    this.onLogout,
    this.immediateCallTestService,
    this.callFinishedEvents,
  });

  final Future<List<Reservation>> Function() loadReservations;
  final List<CallCombinationCard> combinations;
  final ReservationService? reservationService;
  final String? accessToken;
  final Future<void> Function()? onLogout;
  final ImmediateCallTestService? immediateCallTestService;
  final Stream<String>? callFinishedEvents;

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

final class _ReservationListPageState extends State<ReservationListPage>
    with WidgetsBindingObserver {
  late Future<List<Reservation>> _reservationsFuture;
  StreamSubscription<String>? _callFinishedSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reservationsFuture = widget.loadReservations();
    _callFinishedSubscription = widget.callFinishedEvents?.listen((_) {
      unawaited(_reloadReservationsAfterCall());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    setState(() {
      _reservationsFuture = widget.loadReservations();
    });
  }

  @override
  void dispose() {
    unawaited(_callFinishedSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reloadReservationsAfterCall() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }
    setState(() {
      _reservationsFuture = widget.loadReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderBanner(
            title: '예약 목록',
            trailing: widget.onLogout == null
                ? null
                : IconButton(
                    key: const ValueKey('logout-button'),
                    tooltip: '로그아웃',
                    onPressed: () => widget.onLogout!(),
                    icon: const Icon(Icons.logout),
                  ),
          ),
          Expanded(
            child: FutureBuilder<List<Reservation>>(
              future: _reservationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.warning_amber,
                    variant: IconBadgeVariant.danger,
                    message: '예약을 불러오지 못했습니다.',
                    description: '네트워크 상태를 확인한 뒤 다시 시도해주세요.',
                  );
                }
                final reservations = snapshot.data ?? const <Reservation>[];
                if (reservations.isEmpty) {
                  return const EmptyState(
                    icon: Icons.calendar_month,
                    message: '예약된 통화가 없습니다.',
                    description: '페르소나를 골라 첫 예약을 만들어보세요.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
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
          ),
        ],
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
          loadReservation: widget.reservationService == null
              ? null
              : () => widget.reservationService!.get(
                  reservation.reservationId,
                  accessToken: widget.accessToken,
                ),
          callFinishedEvents: widget.callFinishedEvents,
          onStartTestCall: widget.immediateCallTestService == null
              ? null
              : () => _requestIncomingTestCall(context, reservation),
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

  Future<void> _requestIncomingTestCall(
    BuildContext context,
    Reservation reservation,
  ) async {
    final service = widget.immediateCallTestService;
    if (service == null) {
      return;
    }
    try {
      await service.ringIncomingCall(
        reservation.reservationId,
        accessToken: widget.accessToken,
      );
      if (context.mounted) {
        AppSnackbar.showInfo(context, '수신 전화를 전송했습니다.');
      }
    } on ApiError catch (error) {
      if (context.mounted) {
        AppSnackbar.showError(context, error.message);
      }
    }
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
    final shouldCancel = await showOnCueConfirmDialog(
      context,
      title: '예약을 취소할까요?',
      message: '취소한 예약은 다시 사용할 수 없습니다.',
      confirmLabel: '예약 취소',
    );
    if (!shouldCancel || !context.mounted) {
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
      AppSnackbar.showError(context, error.message);
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
    final theme = Theme.of(context);
    final isCancelled = reservation.reservationStatus == 'CANCELLED';

    return Opacity(
      opacity: isCancelled ? 0.55 : 1,
      child: InkWell(
        key: ValueKey('reservation-${reservation.reservationId}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AppCard(
          child: Row(
            children: [
              AppAvatar(
                isRound: true,
                image: combination == null
                    ? null
                    : AssetImage(combination!.personaImageAsset),
                fallback: const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combination?.personaName ?? reservation.personaKey,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _formatScheduledAt(reservation.scheduledAtLocal),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusChip(
                          label: _reservationStatusLabel(
                            reservation.reservationStatus,
                          ),
                          variant: isCancelled
                              ? StatusChipVariant.cancelled
                              : StatusChipVariant.scheduled,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
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
