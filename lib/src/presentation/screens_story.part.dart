part of 'screens.dart';

class DialogueScreen extends StatelessWidget {
  const DialogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChronicleShell(
      current: AppRoute.dialogue,
      title: '스토리 대화 화면',
      subtitle: '전투 전후 컷신과 이름표, 대사창을 공통 대화 레이아웃으로 배치합니다.',
      child: ListView(
        children: const [
          SectionCard(
            title: '도원결의',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('유비: 백성들이 도탄에 빠졌소. 뜻을 함께할 분이 있소?'),
                SizedBox(height: 8),
                Text('관우: 의를 위해 칼을 들겠습니다.'),
                SizedBox(height: 8),
                Text('장비: 오늘부터 형님으로 모시리다!'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DuelScreen extends StatelessWidget {
  const DuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChronicleShell(
      current: AppRoute.duel,
      title: '일기토 연출',
      subtitle: '관우 vs 화웅 같은 지정 조합에서 별도 연출 카드와 결과 보상을 제공합니다.',
      child: Row(
        children: const [
          Expanded(
            child: _DuelPanel(
              name: '관우',
              tag: '도전 · 청룡언월도',
              accent: Faction.shu,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('對', style: TextStyle(fontSize: 36)),
          ),
          Expanded(
            child: _DuelPanel(
              name: '화웅',
              tag: '방어 · 흑철 대도부',
              accent: Faction.enemy,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChronicleShell(
      current: AppRoute.settings,
      title: '설정 화면',
      subtitle: '사운드, 해상도 배율, 입력, 접근성 규칙을 한 곳에 모읍니다.',
      child: ListView(
        children: const [
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: null,
              title: Text('고풍 BGM 활성화'),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: null,
              title: Text('픽셀 정수 배율 사용'),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: false,
              onChanged: null,
              title: Text('색약 보조 대비 강화'),
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChronicleShell(
      current: AppRoute.gameOver,
      title: '게임 오버 씬',
      subtitle: '패배 원인과 재도전 흐름을 명확히 노출합니다.',
      child: Center(
        child: SizedBox(
          width: 520,
          child: SectionCard(
            title: '패배: 유비가 전장에서 쓰러졌습니다',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('원인 요약: 핵심 장수 보호 실패 · 턴 9/10 · 적군 장료의 측면 돌격'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoute.stageBriefing.path),
                      child: const Text('브리핑으로 복귀'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoute.stageSelection.path),
                      child: const Text('스테이지 선택'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
