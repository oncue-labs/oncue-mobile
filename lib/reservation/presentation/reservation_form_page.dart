import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_card.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_app_bar.dart';
import 'package:oncue_mobile/common/design_system/widgets/pill_note.dart';
import 'package:oncue_mobile/common/design_system/widgets/primary_button.dart';
import 'package:oncue_mobile/common/network/api_error.dart';
import 'package:oncue_mobile/common/permissions/permission_guide_page.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class ReservationFormPage extends StatefulWidget {
  const ReservationFormPage({
    super.key,
    required this.combination,
    required this.initialScheduledAtLocal,
    required this.timeZone,
    required this.reservationService,
    this.reservationId,
    this.initialScenarioContext = '',
    this.initialCallGoal = '',
    this.accessToken,
    this.onSaved,
  });

  final CallCombinationCard combination;
  final String? reservationId;
  final String initialScenarioContext;
  final String initialCallGoal;
  final DateTime initialScheduledAtLocal;
  final String timeZone;
  final ReservationService reservationService;
  final String? accessToken;
  final ValueChanged<Reservation>? onSaved;

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

final class _ReservationFormPageState extends State<ReservationFormPage> {
  late final TextEditingController _scenarioContextController;
  late final TextEditingController _callGoalController;
  late DateTime _scheduledAtLocal;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scenarioContextController = TextEditingController(
      text: widget.initialScenarioContext,
    );
    _callGoalController = TextEditingController(text: widget.initialCallGoal);
    _scheduledAtLocal = widget.initialScheduledAtLocal;
  }

  @override
  void dispose() {
    _scenarioContextController.dispose();
    _callGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reservationId != null;
    final theme = Theme.of(context);
    final fieldFill = theme.extension<OnCueColors>()?.surfaceLight;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.extension<OnCueColors>()?.lineStrong ??
            theme.colorScheme.outline,
      ),
    );

    return Scaffold(
      appBar: OnCueAppBar(title: isEditing ? '예약 수정' : '통화 예약'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.combination.personaName,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.combination.scenarioDescription,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('scenario-context-input'),
            controller: _scenarioContextController,
            decoration: InputDecoration(
              labelText: '시나리오 컨텍스트',
              hintText: widget.combination.scenarioContextPlaceholder,
              filled: true,
              fillColor: fieldFill,
              border: fieldBorder,
              enabledBorder: fieldBorder,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('call-goal-input'),
            controller: _callGoalController,
            decoration: InputDecoration(
              labelText: '통화 목표',
              hintText: widget.combination.callGoalPlaceholder,
              filled: true,
              fillColor: fieldFill,
              border: fieldBorder,
              enabledBorder: fieldBorder,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          InkWell(
            key: const ValueKey('scheduled-at-input'),
            borderRadius: BorderRadius.circular(18),
            onTap: _selectScheduledAt,
            child: AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '통화 예정 시각',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatScheduledAt(_scheduledAtLocal),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Icon(Icons.schedule, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const PillNote('예약 시각은 정확히 보장되지 않을 수 있어요.'),
          if (_errorMessage case final error?) ...[
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
                  Icon(Icons.warning_amber, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            key: const ValueKey('reservation-submit-button'),
            onPressed: _isSaving ? null : _saveReservation,
            label: isEditing ? '수정하기' : '예약하기',
          ),
        ],
      ),
    );
  }

  Future<void> _selectScheduledAt() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAtLocal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate == null || !mounted) {
      return;
    }
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAtLocal),
    );
    if (selectedTime == null || !mounted) {
      return;
    }
    setState(() {
      _scheduledAtLocal = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _saveReservation() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final reservationId = widget.reservationId;
      final reservation = reservationId == null
          ? await widget.reservationService.createFromCard(
              combination: widget.combination,
              scenarioContext: _scenarioContextController.text,
              callGoal: _callGoalController.text,
              scheduledAtLocal: _scheduledAtLocal,
              timeZone: widget.timeZone,
              accessToken: widget.accessToken,
            )
          : await widget.reservationService.edit(
              reservationId: reservationId,
              combination: widget.combination,
              scenarioContext: _scenarioContextController.text,
              callGoal: _callGoalController.text,
              scheduledAtLocal: _scheduledAtLocal,
              timeZone: widget.timeZone,
              accessToken: widget.accessToken,
            );
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      widget.onSaved?.call(reservation);
      Navigator.of(context).pop(reservation);
    } on CallPermissionRequiredException {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PermissionGuidePage(
            requestMissingPermissions:
                widget.reservationService.requestMissingPermissions,
            openSettings: widget.reservationService.openPermissionSettings,
          ),
        ),
      );
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = error.message;
      });
    }
  }
}

String _formatScheduledAt(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}
