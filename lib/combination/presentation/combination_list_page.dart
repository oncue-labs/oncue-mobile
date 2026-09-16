import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/data/mvp_call_combinations.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/combination/presentation/combination_detail_page.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';
import 'package:oncue_mobile/reservation/application/reservation_service.dart';

final class CombinationListPage extends StatelessWidget {
  const CombinationListPage({
    super.key,
    this.combinations = MvpCallCombinations.all,
    this.reservationService,
    this.timeZoneProvider,
    this.accessToken,
  });

  final List<CallCombinationCard> combinations;
  final ReservationService? reservationService;
  final DeviceTimeZoneProvider? timeZoneProvider;
  final String? accessToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통화 조합 선택')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
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

    return Card(
      key: ValueKey(cardKey),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PersonaImage(assetPath: combination.personaImageAsset),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combination.personaName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      combination.scenarioSummary,
                      key: ValueKey(summaryKey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          assetPath,
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
