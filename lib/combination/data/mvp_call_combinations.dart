import 'package:oncue_mobile/combination/model/call_combination_card.dart';

abstract final class MvpCallCombinations {
  static const all = <CallCombinationCard>[
    CallCombinationCard(
      personaKey: 'santa',
      scenarioKey: 'child-roleplay',
      personaName: '산타',
      scenarioSummary: '산타가 아이와 이야기하며 편안하게 잠들도록 도와줘요.',
      scenarioDescription:
          '산타클로스가 아이에게 크리스마스 이야기를 들려주고, 오늘 하루를 다정하게 마무리하며 잠들도록 도와주는 역할놀이예요.',
      personaImageAsset: 'assets/images/personas/santa.png',
      previewAudioAsset: 'assets/audio/previews/santa-child-roleplay.wav',
      scenarioContextPlaceholder: '아이 이름, 나이, 산타가 알고 있으면 좋은 이야기를 적어 주세요.',
      callGoalPlaceholder: '예: 아이가 편안한 마음으로 빨리 잠들게 해 주세요.',
    ),
    CallCombinationCard(
      personaKey: 'princess',
      scenarioKey: 'child-roleplay',
      personaName: '공주',
      scenarioSummary: '공주가 아이를 격려하며 즐거운 역할놀이를 해줘요.',
      scenarioDescription:
          '상상 속 공주가 아이의 이야기를 듣고 용기를 북돋아 주며, 아이가 원하는 역할놀이를 함께하는 대화예요.',
      personaImageAsset: 'assets/images/personas/princess.png',
      previewAudioAsset: 'assets/audio/previews/princess-child-roleplay.wav',
      scenarioContextPlaceholder: '아이 이름, 좋아하는 이야기, 원하는 말투를 적어 주세요.',
      callGoalPlaceholder: '예: 아이가 즐겁고 자신감 있는 기분을 느끼게 해 주세요.',
    ),
    CallCombinationCard(
      personaKey: 'friend',
      scenarioKey: 'go-home',
      personaName: '친구',
      scenarioSummary: '친구에게 급한 일이 생긴 것처럼 자연스럽게 집에 돌아가도록 해요.',
      scenarioDescription:
          '친구와 약속 중인 상황에서 친구에게 급한 일이 생겨 집으로 돌아가야 한다고 자연스럽게 알려주는 전화예요.',
      personaImageAsset: 'assets/images/personas/friend.png',
      previewAudioAsset: 'assets/audio/previews/friend-go-home.wav',
      scenarioContextPlaceholder: '친구와 함께 있는 장소, 관계, 자연스러운 말투를 적어 주세요.',
      callGoalPlaceholder: '예: 친구가 급한 일이 생겼다고 생각하고 집에 빨리 돌아가게 해 주세요.',
    ),
    CallCombinationCard(
      personaKey: 'friend',
      scenarioKey: 'travel-friend-introduction',
      personaName: '여행 동행 친구',
      scenarioSummary: '부모님과 통화할 때 여행 동행 친구처럼 자연스럽게 대화해요.',
      scenarioDescription:
          '여행 중 부모님께 친구와 함께 왔다고 소개해야 할 때, 여행 동행 친구의 목소리로 자연스럽게 인사하는 전화예요.',
      personaImageAsset: 'assets/images/personas/travel-friend.png',
      previewAudioAsset: 'assets/audio/previews/travel-friend-introduction.wav',
      scenarioContextPlaceholder: '부모님께 소개할 친구의 이름, 관계, 자연스러운 말투를 적어 주세요.',
      callGoalPlaceholder: '예: 부모님이 여행 동행 친구와 인사했다고 자연스럽게 느끼게 해 주세요.',
    ),
  ];
}
