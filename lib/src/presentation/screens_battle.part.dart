part of 'screens.dart';

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
              selectedAnimationState: selectedAnimation,
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
                Row(
                  children: [
                    BattleUnitSprite(
                      unit: selectedUnit,
                      animationState: selectedAnimation,
                      size: 72,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('애니메이션 상태: $selectedAnimation')),
                  ],
                ),
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
