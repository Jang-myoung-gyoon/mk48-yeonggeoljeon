part of 'screens.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChronicleShell(
      current: AppRoute.title,
      title: '난세영걸전',
      subtitle: '도원결의부터 형주 진입까지 이어지는 압축 삼국지 SRPG 수직 슬라이스',
      child: ListView(
        children: [
          SectionCard(
            title: '키아트 방향',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '후한 말 기록화 + 고전 코에이 감성의 SRPG 톤. 촉한은 청록·백·황, 적군은 흑청·금, 여포 세력은 적흑 색채로 구분합니다.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoute.menu.path),
                  child: const Text('전장을 연다'),
                ),
              ],
            ),
          ),
          const _PillarStrip(),
        ],
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      ('캠페인 시작', AppRoute.stageSelection.path),
      ('장수 관리', AppRoute.officerManagement.path),
      ('전투 HUD 미리보기', AppRoute.battleHud.path),
      ('저장/불러오기', AppRoute.saveLoad.path),
      ('설정', AppRoute.settings.path),
    ];

    return ChronicleShell(
      current: AppRoute.menu,
      title: '메인 메뉴',
      subtitle: '공통 레이아웃과 삼국지 시각 언어를 공유하는 허브',
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.3,
        children: [
          for (final item in menuItems)
            Card(
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(item.$2),
                child: Center(
                  child: Text(
                    item.$1,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
