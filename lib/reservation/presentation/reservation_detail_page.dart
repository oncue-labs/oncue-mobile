import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';
import 'package:oncue_mobile/common/design_system/oncue_typography.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_app_bar.dart';
import 'package:oncue_mobile/common/design_system/widgets/pill_note.dart';
import 'package:oncue_mobile/common/design_system/widgets/status_chip.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class ReservationDetailPage extends StatefulWidget {
  const ReservationDetailPage({
    super.key,
    required this.reservation,
    required this.combination,
    this.now = DateTime.now,
    this.loadReservation,
    this.callFinishedEvents,
    this.onEdit,
    this.onCancel,
    this.onStartTestCall,
  });

  final Reservation reservation;
  final CallCombinationCard combination;
  final DateTime Function() now;
  final Future<Reservation> Function()? loadReservation;
  final Stream<String>? callFinishedEvents;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onCancel;
  final Future<void> Function()? onStartTestCall;

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

final class _ReservationDetailPageState extends State<ReservationDetailPage>
    with WidgetsBindingObserver {
  late Reservation _reservation;
  StreamSubscription<String>? _callFinishedSubscription;

  Reservation get reservation => _reservation;
  CallCombinationCard get combination => widget.combination;
  DateTime Function() get now => widget.now;
  Future<void> Function()? get onEdit => widget.onEdit;
  Future<void> Function()? get onCancel => widget.onCancel;
  Future<void> Function()? get onStartTestCall => widget.onStartTestCall;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
    WidgetsBinding.instance.addObserver(this);
    _callFinishedSubscription = widget.callFinishedEvents?.listen((_) {
      unawaited(_reloadReservationAfterCall());
    });
    unawaited(_reloadReservation());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadReservation();
    }
  }

  @override
  void dispose() {
    unawaited(_callFinishedSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reloadReservationAfterCall() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _reloadReservation();
      if (!mounted || _reservation.callOutcome != null) {
        return;
      }
    }
  }

  Future<void> _reloadReservation() async {
    final loadReservation = widget.loadReservation;
    if (loadReservation == null) {
      return;
    }
    try {
      final refreshedReservation = await loadReservation();
      if (!mounted) {
        return;
      }
      setState(() {
        _reservation = refreshedReservation;
      });
    } catch (_) {
      // Keep the last known reservation when a background refresh fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit;
    final theme = Theme.of(context);
    final lineStrong =
        theme.extension<OnCueColors>()?.lineStrong ?? theme.colorScheme.outline;

    return Scaffold(
      appBar: const OnCueAppBar(title: '예약 상세'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PersonaImage(assetPath: combination.personaImageAsset),
          const SizedBox(height: 16),
          Text(combination.personaName, style: pageTitleStyle(context)),
          const SizedBox(height: 4),
          Text(
            combination.scenarioDescription,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            label: '예약 상태',
            valueWidget: StatusChip(
              label: _reservationStatusLabel,
              variant: reservation.reservationStatus == 'CANCELLED'
                  ? StatusChipVariant.cancelled
                  : StatusChipVariant.scheduled,
            ),
            lineColor: lineStrong,
          ),
          _DetailRow(
            label: '통화 상태',
            value: _callStatusLabel,
            lineColor: lineStrong,
          ),
          _DetailRow(
            label: '통화 결과',
            value: _callOutcomeLabel,
            lineColor: lineStrong,
          ),
          _DetailRow(
            label: '예약 시각',
            value: _formatScheduledAt(reservation.scheduledAtLocal),
            lineColor: lineStrong,
          ),
          _DetailRow(
            label: '시간대',
            value: reservation.timeZone,
            lineColor: lineStrong,
          ),
          _DetailRow(
            label: '수정 가능 마감',
            value: _formatScheduledAt(reservation.editableUntil.toLocal()),
            lineColor: lineStrong,
            showDivider: false,
          ),
          const SizedBox(height: 16),
          Text(
            '시나리오 컨텍스트',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(reservation.scenarioContext ?? '입력하지 않음'),
          const SizedBox(height: 16),
          Text(
            '통화 목표',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(reservation.callGoal ?? '입력하지 않음'),
          const SizedBox(height: 16),
          const PillNote('예약 시각은 정확히 보장되지 않을 수 있어요.'),
          if (onStartTestCall != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const ValueKey('local-test-call-button'),
              onPressed: onStartTestCall,
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('개발용 즉시 통화'),
            ),
          ],
          if (!canEdit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '통화 5분 전부터는 예약을 수정할 수 없습니다.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            key: const ValueKey('edit-reservation-button'),
            onPressed: canEdit && onEdit != null ? onEdit : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: lineStrong),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size.fromHeight(0),
            ),
            child: const Text('예약 수정'),
          ),
          TextButton(
            key: const ValueKey('cancel-reservation-button'),
            onPressed: canEdit && onCancel != null ? onCancel : null,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );
  }

  bool get _canEdit {
    return reservation.reservationStatus == 'SCHEDULED' &&
        reservation.callOutcome == null &&
        now().isBefore(reservation.editableUntil);
  }

  String get _reservationStatusLabel {
    return switch (reservation.reservationStatus) {
      'SCHEDULED' => '예약됨',
      'CANCELLED' => '취소됨',
      _ => reservation.reservationStatus,
    };
  }

  String get _callStatusLabel {
    if (reservation.endedAt != null && reservation.callOutcome != null) {
      return '완료';
    }
    return switch (reservation.callStatus) {
      'RINGING' => '수신 대기',
      'CONNECTING' => '연결 중',
      'IN_CALL' => '통화 중',
      null => '준비 전',
      _ => reservation.callStatus!,
    };
  }

  String get _callOutcomeLabel {
    return switch (reservation.callOutcome) {
      'SUCCEEDED' => '완료',
      'FAILED' => '실패',
      null => '진행 중',
      _ => reservation.callOutcome!,
    };
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    required this.lineColor,
    this.showDivider = true,
  }) : assert(
         value != null || valueWidget != null,
         'either value or valueWidget must be given',
       );

  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color lineColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: lineColor)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: valueWidget ?? Text(value!),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PersonaImage extends StatelessWidget {
  const _PersonaImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFE8EAF6),
            child: Icon(Icons.person, size: 64),
          ),
        ),
      ),
    );
  }
}

String _formatScheduledAt(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}
