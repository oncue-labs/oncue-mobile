final class CallCombinationCard {
  const CallCombinationCard({
    required this.personaKey,
    required this.scenarioKey,
    required this.personaName,
    required this.scenarioSummary,
    required this.scenarioDescription,
    required this.personaImageAsset,
    required this.previewAudioAsset,
    required this.scenarioContextPlaceholder,
    required this.callGoalPlaceholder,
  });

  final String personaKey;
  final String scenarioKey;
  final String personaName;
  final String scenarioSummary;
  final String scenarioDescription;
  final String personaImageAsset;
  final String previewAudioAsset;
  final String scenarioContextPlaceholder;
  final String callGoalPlaceholder;
}
