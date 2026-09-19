import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/common/design_system/oncue_colors.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_app_bar.dart';
import 'package:oncue_mobile/common/design_system/widgets/outline_button.dart';
import 'package:oncue_mobile/common/design_system/widgets/primary_button.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';
import 'package:oncue_mobile/reservation/presentation/reservation_form_page.dart';

final class CombinationDetailPage extends StatefulWidget {
  const CombinationDetailPage({
    super.key,
    required this.combination,
    this.reservationService,
    this.timeZoneProvider,
    this.accessToken,
  });

  final CallCombinationCard combination;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;

  @override
  State<CombinationDetailPage> createState() => _CombinationDetailPageState();
}

final class _CombinationDetailPageState extends State<CombinationDetailPage> {
  late final TextEditingController _scenarioContextController;
  late final TextEditingController _callGoalController;

  @override
  void initState() {
    super.initState();
    _scenarioContextController = TextEditingController();
    _callGoalController = TextEditingController();
  }

  @override
  void dispose() {
    _scenarioContextController.dispose();
    _callGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      appBar: OnCueAppBar(title: widget.combination.personaName),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailPersonaImage(assetPath: widget.combination.personaImageAsset),
          const SizedBox(height: 16),
          Text(
            widget.combination.personaName,
            key: ValueKey('detail-persona-${widget.combination.personaKey}'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.combination.scenarioDescription,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlineButton(
            onPressed: null,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: '10초 미리듣기',
          ),
          const SizedBox(height: 6),
          Text(
            '음성 미리듣기는 준비 중입니다.',
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
          if (widget.reservationService != null &&
              widget.timeZoneProvider != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              key: const ValueKey('reserve-combination-button'),
              onPressed: () => _openReservationForm(context),
              label: '예약 정보 입력',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReservationForm(BuildContext context) async {
    final service = widget.reservationService;
    final provider = widget.timeZoneProvider;
    if (service == null || provider == null) {
      return;
    }
    try {
      final timeZone = await provider.currentTimeZone();
      if (!context.mounted) {
        return;
      }
      final savedReservation = await Navigator.of(context).push<Reservation>(
        MaterialPageRoute<Reservation>(
          builder: (_) => ReservationFormPage(
            combination: widget.combination,
            initialScheduledAtLocal: DateTime.now().add(
              const Duration(minutes: 10),
            ),
            initialScenarioContext: _scenarioContextController.text,
            initialCallGoal: _callGoalController.text,
            timeZone: timeZone,
            reservationService: service,
            accessToken: widget.accessToken,
          ),
        ),
      );
      if (!context.mounted || savedReservation == null) {
        return;
      }
      Navigator.of(context).pop(savedReservation);
    } on StateError catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

final class _DetailPersonaImage extends StatelessWidget {
  const _DetailPersonaImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
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
