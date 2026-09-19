import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class ReservationDetailPage extends StatelessWidget {
  const ReservationDetailPage({
    super.key,
    required this.reservation,
    required this.combination,
    this.now = DateTime.now,
    this.onEdit,
    this.onCancel,
    this.onStartTestCall,
  });

  final Reservation reservation;
  final CallCombinationCard combination;
  final DateTime Function() now;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onCancel;
  final Future<void> Function()? onStartTestCall;

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit;
    return Scaffold(
      appBar: AppBar(title: const Text('예약 상세')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PersonaImage(assetPath: combination.personaImageAsset),
          const SizedBox(height: 16),
          Text(
            combination.personaName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(combination.scenarioDescription),
          const SizedBox(height: 24),
          _DetailRow(label: '예약 상태', value: _reservationStatusLabel),
          _DetailRow(label: '통화 상태', value: _callStatusLabel),
          _DetailRow(label: '통화 결과', value: _callOutcomeLabel),
          _DetailRow(
            label: '예약 시각',
            value: _formatScheduledAt(reservation.scheduledAtLocal),
          ),
          _DetailRow(label: '시간대', value: reservation.timeZone),
          _DetailRow(
            label: '수정 가능 마감',
            value: _formatScheduledAt(reservation.editableUntil.toLocal()),
          ),
          const SizedBox(height: 16),
          const Text('시나리오 컨텍스트'),
          const SizedBox(height: 4),
          Text(reservation.scenarioContext ?? '입력하지 않음'),
          const SizedBox(height: 16),
          const Text('통화 목표'),
          const SizedBox(height: 4),
          Text(reservation.callGoal ?? '입력하지 않음'),
          const SizedBox(height: 16),
          const Text('예약 시각은 정확히 보장되지 않을 수 있어요.'),
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
            const SizedBox(height: 8),
            const Text('통화 5분 전부터는 예약을 수정할 수 없습니다.'),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            key: const ValueKey('edit-reservation-button'),
            onPressed: canEdit && onEdit != null ? onEdit : null,
            child: const Text('예약 수정'),
          ),
          TextButton(
            key: const ValueKey('cancel-reservation-button'),
            onPressed: canEdit && onCancel != null ? onCancel : null,
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
      'SUCCEEDED' => '성공',
      'FAILED' => '실패',
      null => '진행 중',
      _ => reservation.callOutcome!,
    };
  }
}

final class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label)),
          Expanded(child: Text(value)),
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
