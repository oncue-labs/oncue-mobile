import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/combination/presentation/combination_detail_page.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_avatar.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_card.dart';
import 'package:oncue_mobile/common/design_system/widgets/empty_state.dart';
import 'package:oncue_mobile/common/design_system/widgets/header_banner.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';

final class CombinationListPage extends StatelessWidget {
  const CombinationListPage({
    super.key,
    this.combinations = MvpCallCombinations.all,
    this.reservationService,
    this.timeZoneProvider,
    this.accessToken,
    this.onLogout,
  });

  final List<CallCombinationCard> combinations;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderBanner(
            title: '전화 예약',
            trailing: onLogout == null
                ? null
                : IconButton(
                    key: const ValueKey('logout-button'),
                    tooltip: '로그아웃',
                    onPressed: () => onLogout!(),
                    icon: const Icon(Icons.logout),
                  ),
          ),
          Expanded(
            child: combinations.isEmpty
                ? const EmptyState(
                    icon: Icons.auto_awesome,
                    message: '아직 공개된 페르소나가 없어요',
                    description: '새로운 조합이 열리면 가장 먼저 알려드릴게요.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                    itemCount: combinations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final combination = combinations[index];
                      return _CombinationCardTile(
                        combination: combination,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CombinationDetailPage(
                                combination: combination,
                                reservationService: reservationService,
                                timeZoneProvider: timeZoneProvider,
                                accessToken: accessToken,
                              ),
                            ),
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
}

final class _CombinationCardTile extends StatelessWidget {
  const _CombinationCardTile({required this.combination, required this.onTap});

  final CallCombinationCard combination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardKey =
        'combination-card-${combination.personaKey}-${combination.scenarioKey}';
    final summaryKey =
        'summary-${combination.personaKey}-${combination.scenarioKey}';
    final theme = Theme.of(context);

    return InkWell(
      key: ValueKey(cardKey),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              size: 60,
              image: AssetImage(combination.personaImageAsset),
              fallback: const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combination.personaName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    combination.scenarioSummary,
                    key: ValueKey(summaryKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
