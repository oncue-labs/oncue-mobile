import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';

final class CombinationDetailPage extends StatelessWidget {
  const CombinationDetailPage({
    super.key,
    required this.combination,
  });

  final CallCombinationCard combination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(combination.personaName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailPersonaImage(assetPath: combination.personaImageAsset),
          const SizedBox(height: 16),
          Text(
            combination.personaName,
            key: ValueKey('detail-persona-${combination.personaKey}'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(combination.scenarioDescription),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('10초 미리듣기'),
          ),
          const Text('음성 미리듣기는 준비 중입니다.'),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('scenario-context-input'),
            decoration: InputDecoration(
              labelText: '시나리오 컨텍스트',
              hintText: combination.scenarioContextPlaceholder,
              border: const OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('call-goal-input'),
            decoration: InputDecoration(
              labelText: '통화 목표',
              hintText: combination.callGoalPlaceholder,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
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
