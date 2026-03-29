import 'package:flutter/material.dart';

import '../app/app.dart';
import '../domain/campaign_models.dart';
import '../data/game_data.dart';
import '../domain/battle_engine.dart';
import '../domain/models.dart';
import 'ui_palette_extensions.dart';

String _leadingGlyph(String text) => text.isEmpty ? '?' : text.substring(0, 1);

class ChronicleShell extends StatelessWidget {
  const ChronicleShell({
    super.key,
    required this.current,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final AppRoute current;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final specs = NanseHeroesApp.routeSpecs;
    final currentSpec = specs.firstWhere((spec) => spec.route == current);
    final navItems = [
      for (final spec in specs)
        ListTile(
          selected: spec.route == current,
          title: Text(spec.label),
          onTap: () {
            Navigator.of(context).pushReplacementNamed(spec.route.path);
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: SafeArea(child: ListView(children: navItems)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1080;
          return Row(
            children: [
              if (wide)
                SizedBox(
                  width: 280,
                  child: Card(child: ListView(children: navItems)),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSpec.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

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

class StageSelectionScreen extends StatelessWidget {
  const StageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = InheritedGameData.of(context);
    final session = InheritedGameSession.of(context);
    return ChronicleShell(
      current: AppRoute.stageSelection,
      title: '스테이지 선택',
      subtitle: '진행도에 따라 해금된 전장만 선택할 수 있습니다.',
      child: ListView(
        children: [
          for (final stage in data.stages)
            Card(
              child: ListTile(
                selected: session.campaignState.selectedStageId == stage.id,
                title: Text('Stage ${stage.id}. ${stage.name}'),
                subtitle: Text(
                  '${stage.motif} · 목표 승률 ${(stage.targetWinRate * 100).round()}% · '
                  '${session.campaignState.unlockedStageIds.contains(stage.id) ? '해금됨' : '잠김'}',
                ),
                trailing: FilledButton(
                  onPressed: session.campaignState.unlockedStageIds.contains(stage.id)
                      ? () {
                          session.selectStage(stage.id);
                          Navigator.of(context).pushNamed(AppRoute.stageBriefing.path);
                        }
                      : null,
                  child: const Text('브리핑'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StageBriefingScreen extends StatelessWidget {
  const StageBriefingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stage = InheritedGameSession.of(context).selectedStage;
    return ChronicleShell(
      current: AppRoute.stageBriefing,
      title: '스테이지 브리핑',
      subtitle: 'SC-04 — 승리 조건과 패배 조건, 기믹을 전투 전에 요약합니다.',
      child: ListView(
        children: [
          SectionCard(
            title: stage.name,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FactChip(label: '목표', value: stage.objective),
                _FactChip(label: '패배 조건', value: stage.lossCondition),
                _FactChip(label: '턴 제한', value: '${stage.turnLimit}턴'),
                _FactChip(label: '기믹', value: stage.gimmick),
              ],
            ),
          ),
          SectionCard(
            title: '출전 장수',
            child: Column(
              children: [
                for (final unit in stage.playerUnits)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: unit.profile.faction.color,
                      child: Text(_leadingGlyph(unit.profile.name)),
                    ),
                    title: Text(unit.profile.name),
                    subtitle: Text(
                      '${unit.profile.title} · ${unit.profile.signature}',
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoute.formation.path),
              child: const Text('편성으로 이동'),
            ),
          ),
        ],
      ),
    );
  }
}

class FormationScreen extends StatelessWidget {
  const FormationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    final stage = session.selectedStage;
    final progress = session.campaignState.officerProgress;
    final selectedIds = session.campaignState.selectedFormationIds.toSet();
    return ChronicleShell(
      current: AppRoute.formation,
      title: '편성/준비 화면',
      subtitle: '출전 편성, 성장 상태, 장비 슬롯을 실제 캠페인 데이터와 연결합니다.',
      child: ListView(
        children: [
          SectionCard(
            title: '출전 슬롯',
            child: Column(
              children: [
                for (final officer in session.availableOfficers)
                  _OfficerTile(
                    profile: officer,
                    note:
                        'Lv.${progress[officer.id]!.level} · EXP ${progress[officer.id]!.experience} · '
                        '장비 ${progress[officer.id]!.equipmentSlots.join(', ')}',
                    trailing: FilterChip(
                      label: Text(selectedIds.contains(officer.id) ? '출전 중' : '대기'),
                      selected: selectedIds.contains(officer.id),
                      onSelected: (_) => session.toggleFormation(officer.id),
                    ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '예상 적 정보',
            child: Column(
              children: [
                for (final unit in stage.enemyUnits)
                  _OfficerTile(
                    profile: unit.profile,
                    note: '위협: ${unit.profile.signature}',
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                session.startSelectedStage();
                Navigator.of(context).pushNamed(AppRoute.battleHud.path);
              },
              child: const Text('전투 시작'),
            ),
          ),
        ],
      ),
    );
  }
}

class BattleHudScreen extends StatefulWidget {
  const BattleHudScreen({super.key});

  @override
  State<BattleHudScreen> createState() => _BattleHudScreenState();
}

enum PlayerCommandMode { move, attack, tactic, item }

class _BattleHudScreenState extends State<BattleHudScreen> {
  late BattleState state;
  String selectedUnitId = 'liu-bei';
  PlayerCommandMode commandMode = PlayerCommandMode.move;
  final Map<String, String> animationStates = <String, String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeBattleState();
  }

  void _initializeBattleState() {
    final session = InheritedGameSession.of(context);
    state = session.currentBattle ?? session.startSelectedStage(notify: false);
    selectedUnitId = state.livingUnits(Faction.shu).first.id;
    commandMode = PlayerCommandMode.move;
    _resetAnimations();
  }

  void _endTurn() {
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.endPlayerTurn(state);
      session.updateCurrentBattle(state);
      _resetAnimations();
    });
  }

  void _reset() {
    final session = InheritedGameSession.of(context);
    setState(() {
      state = session.startSelectedStage();
      selectedUnitId = state.livingUnits(Faction.shu).first.id;
      commandMode = PlayerCommandMode.move;
      _resetAnimations();
    });
  }

  void _resetAnimations() {
    animationStates
      ..clear()
      ..addEntries(
        state.livingUnits(Faction.shu).map((unit) => MapEntry(unit.id, 'idle')),
      );
  }

  BattleUnit get _selectedUnit {
    return state.units.firstWhere(
      (unit) => unit.id == selectedUnitId,
      orElse: () {
        final livingHeroes = state.livingUnits(Faction.shu);
        return livingHeroes.isNotEmpty ? livingHeroes.first : state.units.first;
      },
    );
  }

  List<GridPoint> get _reachableTiles =>
      BattleEngine.reachableTiles(state, _selectedUnit);

  List<BattleUnit> get _attackableEnemies =>
      BattleEngine.attackableTargets(state, _selectedUnit);

  List<BattleUnit> get _tacticTargets =>
      BattleEngine.tacticTargets(state, _selectedUnit);

  List<BattleUnit> get _itemTargets =>
      BattleEngine.itemTargets(state, _selectedUnit);

  void _selectUnit(String unitId) {
    setState(() {
      selectedUnitId = unitId;
      commandMode = PlayerCommandMode.move;
    });
  }

  void _moveSelected(GridPoint destination) {
    final selectedId = _selectedUnit.id;
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.moveUnit(
        state,
        unitId: selectedId,
        destination: destination,
      );
      session.updateCurrentBattle(state);
      animationStates[selectedId] = 'idle';
    });
  }

  void _attackSelected(String targetId) {
    final selectedId = _selectedUnit.id;
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.attackUnit(
        state,
        attackerId: selectedId,
        targetId: targetId,
      );
      session.updateCurrentBattle(state);
      animationStates[selectedId] = 'attack';
    });
  }

  void _tacticSelected(String targetId) {
    final selectedId = _selectedUnit.id;
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.useTactic(
        state,
        casterId: selectedId,
        targetId: targetId,
      );
      session.updateCurrentBattle(state);
      animationStates[selectedId] = 'attack';
      commandMode = PlayerCommandMode.move;
    });
  }

  void _itemSelected(String targetId) {
    final selectedId = _selectedUnit.id;
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.useItem(
        state,
        userId: selectedId,
        targetId: targetId,
      );
      session.updateCurrentBattle(state);
      animationStates[selectedId] = 'idle';
      commandMode = PlayerCommandMode.move;
    });
  }

  void _waitSelected() {
    final selectedId = _selectedUnit.id;
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.waitUnit(state, unitId: selectedId);
      session.updateCurrentBattle(state);
      animationStates[selectedId] = 'idle';
      commandMode = PlayerCommandMode.move;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stage = state.stage;
    final aliveHeroes = state.livingUnits(Faction.shu).length;
    final aliveEnemies = state.livingUnits(Faction.enemy).length;
    final selectedUnit = _selectedUnit;
    final selectedAnimation = animationStates[selectedUnit.id] ?? 'idle';
    final reachableTiles = _reachableTiles;
    final attackableEnemies = _attackableEnemies;
    final tacticTargets = _tacticTargets;
    final itemTargets = _itemTargets;

    return ChronicleShell(
      current: AppRoute.battleHud,
      title: '전투 메인 HUD',
      subtitle: '코어 로직과 UI가 분리된 상태에서 아군 장수를 직접 선택하고 이동/공격/대기를 실행할 수 있습니다.',
      actions: [
        TextButton(onPressed: _reset, child: const Text('리셋')),
        FilledButton(
          onPressed: state.outcome == BattleOutcome.ongoing ? _endTurn : _reset,
          child: Text(state.outcome == BattleOutcome.ongoing ? '턴 종료' : '재시작'),
        ),
      ],
      child: ListView(
        key: const ValueKey('battle-hud-scroll'),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FactChip(label: '턴', value: '${state.turn}/${stage.turnLimit}'),
              _FactChip(
                label: '위상',
                value: state.phase == BattlePhase.player ? '아군' : '적군',
              ),
              _FactChip(label: '아군 생존', value: '$aliveHeroes'),
              _FactChip(label: '적군 생존', value: '$aliveEnemies'),
              _FactChip(
                label: '결과',
                value: switch (state.outcome) {
                  BattleOutcome.ongoing => '진행 중',
                  BattleOutcome.victory => '승리',
                  BattleOutcome.defeat => '패배',
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '전장 타일맵',
            child: _BattleGrid(
              state: state,
              selectedUnitId: selectedUnit.id,
              highlightedTiles: commandMode == PlayerCommandMode.move
                  ? reachableTiles.toSet()
                  : <GridPoint>{},
              attackableUnitIds: commandMode == PlayerCommandMode.attack
                  ? attackableEnemies.map((unit) => unit.id).toSet()
                  : <String>{},
              onUnitSelected: _selectUnit,
              onTileSelected: _moveSelected,
            ),
          ),
          SectionCard(
            title: '선택 유닛 패널',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final unit in state.livingUnits(Faction.shu))
                      ChoiceChip(
                        label: Text(unit.name),
                        selected: unit.id == selectedUnit.id,
                        onSelected: (_) => _selectUnit(unit.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${selectedUnit.name} · ${selectedUnit.unitClass.label} · Lv.${selectedUnit.level}',
                ),
                const SizedBox(height: 8),
                Text(
                  'HP ${selectedUnit.hp}/${selectedUnit.maxHp} · 공격 ${selectedUnit.attack} · 방어 ${selectedUnit.defense} · 이동 ${selectedUnit.mobility} · 사거리 ${selectedUnit.range}',
                ),
                const SizedBox(height: 8),
                Text('애니메이션 상태: $selectedAnimation'),
                const SizedBox(height: 8),
                Text('고유 강점: ${selectedUnit.signature}'),
              ],
            ),
          ),
          SectionCard(
            title: '커맨드 버튼',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      setState(() => commandMode = PlayerCommandMode.move),
                  child: const Text('이동'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      setState(() => commandMode = PlayerCommandMode.attack),
                  child: const Text('공격'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() => commandMode = PlayerCommandMode.tactic);
                  },
                  child: const Text('책략'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() => commandMode = PlayerCommandMode.item);
                  },
                  child: const Text('도구'),
                ),
                FilledButton(onPressed: _waitSelected, child: const Text('대기')),
              ],
            ),
          ),
          SectionCard(
            title: switch (commandMode) {
              PlayerCommandMode.attack => '공격 목표',
              PlayerCommandMode.tactic => '책략 목표',
              PlayerCommandMode.item => '도구 대상',
              _ => '이동 후보',
            },
            child: commandMode == PlayerCommandMode.attack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (attackableEnemies.isEmpty)
                        const Text('현재 사거리 안에 공격 가능한 적이 없습니다.'),
                      for (final enemy in attackableEnemies)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(enemy.name),
                          subtitle: Text(
                            'HP ${enemy.hp}/${enemy.maxHp} · ${enemy.unitClass.label}',
                          ),
                          trailing: FilledButton(
                            onPressed: () => _attackSelected(enemy.id),
                            child: const Text('공격 실행'),
                          ),
                        ),
                    ],
                  )
                : commandMode == PlayerCommandMode.tactic
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tacticTargets.isEmpty)
                        const Text('현재 책략 사거리 안에 목표가 없습니다.'),
                      for (final enemy in tacticTargets)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(enemy.name),
                          subtitle: Text(
                            'HP ${enemy.hp}/${enemy.maxHp} · ${enemy.unitClass.label}',
                          ),
                          trailing: FilledButton(
                            onPressed: () => _tacticSelected(enemy.id),
                            child: const Text('책략 실행'),
                          ),
                        ),
                    ],
                  )
                : commandMode == PlayerCommandMode.item
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (itemTargets.isEmpty)
                        const Text('현재 도구를 사용할 수 있는 아군이 없습니다.'),
                      for (final ally in itemTargets)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(ally.name),
                          subtitle: Text('HP ${ally.hp}/${ally.maxHp} · 인접 회복'),
                          trailing: FilledButton(
                            onPressed: () => _itemSelected(ally.id),
                            child: const Text('도구 사용'),
                          ),
                        ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tile in reachableTiles)
                        ActionChip(
                          label: Text('(${tile.x}, ${tile.y})'),
                          onPressed: () => _moveSelected(tile),
                        ),
                    ],
                  ),
          ),
          SectionCard(
            title: '행동 로그',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in state.log.take(10).toList().reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $line'),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: '행동 메뉴 정책',
            child: const Text(
              '수동 플레이 기준 커맨드: 이동 / 공격 / 책략 / 도구 / 대기 / 턴 종료. 전장 타일과 목표 버튼은 코어 BattleEngine.moveUnit / attackUnit / useTactic / useItem / waitUnit 에 직접 연결되고, 턴 종료는 endPlayerTurn으로 분리됩니다.',
            ),
          ),
        ],
      ),
    );
  }
}

class BattleInspectorScreen extends StatelessWidget {
  const BattleInspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = BattleEngine.createInitialState(
      InheritedGameData.of(context).stages.first,
    );
    final sampleUnit = state.units.first;
    final terrain = BattleEngine.terrainAt(state, sampleUnit.x, sampleUnit.y);

    return ChronicleShell(
      current: AppRoute.battleInspector,
      title: '전투 상세 정보창',
      subtitle: '유닛 능력치, 지형 효과, 사거리를 공통 패널로 보여줍니다.',
      child: ListView(
        children: [
          SectionCard(
            title: sampleUnit.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${sampleUnit.unitClass.label} · Lv.${sampleUnit.level}'),
                const SizedBox(height: 8),
                Text(
                  'HP ${sampleUnit.hp}/${sampleUnit.maxHp} · 공격 ${sampleUnit.attack} · 방어 ${sampleUnit.defense} · 이동 ${sampleUnit.mobility} · 사거리 ${sampleUnit.range}',
                ),
                const SizedBox(height: 8),
                Text('서 있는 지형: ${terrain.label} (방어 +${terrain.defenseBonus})'),
                const SizedBox(height: 8),
                Text('고유 강점: ${sampleUnit.signature}'),
              ],
            ),
          ),
          SectionCard(
            title: '이동 가능 타일',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tile in BattleEngine.reachableTiles(
                  state,
                  sampleUnit,
                ).take(12))
                  Chip(label: Text('(${tile.x}, ${tile.y})')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    final report = session.lastResult;
    return ChronicleShell(
      current: AppRoute.result,
      title: '결과 화면',
      subtitle: '경험치, 획득 아이템, 다음 스테이지 해금 상태를 실제 전투 정산으로 표시합니다.',
      child: ListView(
        children: [
          SectionCard(
            title: '전투 요약',
            child: report == null
                ? const Text('아직 정산할 전투 결과가 없습니다.')
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _FactChip(label: '스테이지', value: 'Stage ${report.stageId}'),
                      _FactChip(
                        label: '결과',
                        value: report.outcome == BattleOutcome.victory ? '승리' : '패배',
                      ),
                      _FactChip(label: '보상', value: '${report.items.length}개'),
                      _FactChip(
                        label: '해금',
                        value: report.unlockedStageIds.isEmpty
                            ? '없음'
                            : report.unlockedStageIds.join(', '),
                      ),
                    ],
                  ),
          ),
          SectionCard(
            title: '성장/보상',
            child: report == null
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      for (final entry in report.experienceAwards.entries)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: InheritedGameData.of(
                              context,
                            ).getOfficer(entry.key).faction.color,
                            child: Text(
                              _leadingGlyph(
                                InheritedGameData.of(
                                  context,
                                ).getOfficer(entry.key).name,
                              ),
                            ),
                          ),
                          title: Text(
                            InheritedGameData.of(context).getOfficer(entry.key).name,
                          ),
                          subtitle: Text('경험치 +${entry.value}'),
                        ),
                      if (report.items.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('획득 아이템: ${report.items.join(', ')}'),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: session.applyLastResult,
                        child: const Text('정산 적용'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class OfficerManagementScreen extends StatelessWidget {
  const OfficerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    final roster = session.availableOfficers;
    final progress = session.campaignState.officerProgress;
    return ChronicleShell(
      current: AppRoute.officerManagement,
      title: '장수 관리 화면',
      subtitle: '레벨, 경험치, 장비/소모품 슬롯, 합류 시점을 실제 캠페인 상태에서 읽어옵니다.',
      child: ListView(
        children: [
          for (final officer in roster)
            _OfficerTile(
              profile: officer,
              note:
                  'Lv.${progress[officer.id]!.level} · EXP ${progress[officer.id]!.experience} · '
                  '합류 Stage ${progress[officer.id]!.availableFromStageId}\n'
                  '장비 ${progress[officer.id]!.equipmentSlots.join(', ')} · '
                  '소모품 ${progress[officer.id]!.consumableSlots.join(', ')}',
            ),
        ],
      ),
    );
  }
}

class SaveLoadScreen extends StatelessWidget {
  const SaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = InheritedGameSession.of(context);
    return ChronicleShell(
      current: AppRoute.saveLoad,
      title: '저장/불러오기',
      subtitle: '현재 스테이지, 턴, 편성, 성장, 인벤토리, 전투 상태를 슬롯으로 저장합니다.',
      child: ListView(
        children: [
          for (final slot in SaveSlotId.values)
            Card(
              child: ListTile(
                title: Text(
                  session.slots[slot]?.label ?? '${slot.name} · 빈 슬롯',
                ),
                subtitle: Text(
                  session.slots[slot]?.savedAtIso ??
                      '현재 캠페인 상태를 여기에 저장할 수 있습니다.',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => session.loadFromSlot(slot),
                      child: const Text('불러오기'),
                    ),
                    FilledButton(
                      onPressed: () => session.saveToSlot(slot),
                      child: const Text('저장'),
                    ),
                  ],
                ),
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

class _PillarStrip extends StatelessWidget {
  const _PillarStrip();

  @override
  Widget build(BuildContext context) {
    final pillars = const [
      '유비 중심의 압축 서사',
      '미션형 SRPG 전장',
      '소수 정예 장수 육성',
      '삼국지 정체성이 분명한 아트/사운드',
    ];
    return SectionCard(
      title: '프로덕트 필러',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final item in pillars) Chip(label: Text(item))],
      ),
    );
  }
}

class _OfficerTile extends StatelessWidget {
  const _OfficerTile({
    required this.profile,
    required this.note,
    this.trailing,
  });

  final OfficerProfile profile;
  final String note;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: profile.faction.color,
          child: Text(_leadingGlyph(profile.name)),
        ),
        title: Text('${profile.name} · ${profile.title}'),
        subtitle: Text('$note\n${profile.visual}'),
        isThreeLine: true,
        trailing: trailing ?? Text('Lv.${profile.level}'),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _BattleGrid extends StatelessWidget {
  const _BattleGrid({
    required this.state,
    required this.selectedUnitId,
    required this.highlightedTiles,
    required this.attackableUnitIds,
    required this.onUnitSelected,
    required this.onTileSelected,
  });

  final BattleState state;
  final String selectedUnitId;
  final Set<GridPoint> highlightedTiles;
  final Set<String> attackableUnitIds;
  final ValueChanged<String> onUnitSelected;
  final ValueChanged<GridPoint> onTileSelected;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var y = 0; y < state.stage.height; y++) {
      for (var x = 0; x < state.stage.width; x++) {
        final terrain = BattleEngine.terrainAt(state, x, y);
        final unit = state.units
            .where(
              (candidate) =>
                  candidate.alive && candidate.x == x && candidate.y == y,
            )
            .cast<BattleUnit?>()
            .firstOrNull;
        final point = GridPoint(x, y);
        final isHighlighted = highlightedTiles.contains(point);
        final isSelected = unit?.id == selectedUnitId;
        final isAttackable =
            unit != null && attackableUnitIds.contains(unit.id);
        cells.add(
          InkWell(
            key: ValueKey('battle-cell-$x-$y'),
            onTap: () {
              if (unit != null && unit.faction == Faction.shu) {
                onUnitSelected(unit.id);
                return;
              }
              if (isHighlighted) {
                onTileSelected(point);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: terrain.color,
                border: Border.all(
                  color: isSelected
                      ? Colors.amberAccent
                      : isAttackable
                      ? Colors.redAccent
                      : isHighlighted
                      ? Colors.white70
                      : Colors.black45,
                  width: isSelected || isAttackable || isHighlighted ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Text(
                      _leadingGlyph(terrain.label),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  if (unit != null)
                    Center(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: unit.faction.color,
                        child: Text(unit.shortName),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return AspectRatio(
      aspectRatio: state.stage.width / state.stage.height,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: state.stage.width,
        childAspectRatio: 1,
        children: cells,
      ),
    );
  }
}

class _DuelPanel extends StatelessWidget {
  const _DuelPanel({
    required this.name,
    required this.tag,
    required this.accent,
  });

  final String name;
  final String tag;
  final Faction accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: accent.color,
                child: Text(
                  _leadingGlyph(name),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(tag),
            ],
          ),
        ),
      ),
    );
  }
}
