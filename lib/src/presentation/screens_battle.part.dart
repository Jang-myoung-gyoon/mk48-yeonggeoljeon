part of 'screens.dart';

class BattleHudScreen extends StatefulWidget {
  const BattleHudScreen({super.key});

  @override
  State<BattleHudScreen> createState() => _BattleHudScreenState();
}

enum PlayerCommandMode { move, attack, tactic, item }

enum _BattleMenuAction { move, attack, tactic, item, wait }

enum _BattleFloatTone { damage, heal }

enum _BattleParticleKind { attack, tactic }

class _BattleFloatingTextEntry {
  const _BattleFloatingTextEntry({
    required this.id,
    required this.position,
    required this.text,
    required this.tone,
  });

  final String id;
  final GridPoint position;
  final String text;
  final _BattleFloatTone tone;
}

class _BattleParticleEntry {
  const _BattleParticleEntry({
    required this.id,
    required this.position,
    required this.kind,
  });

  final String id;
  final GridPoint position;
  final _BattleParticleKind kind;
}

class _BattleHudScreenState extends State<BattleHudScreen> {
  late BattleState state;
  String selectedUnitId = 'liu-bei';
  PlayerCommandMode commandMode = PlayerCommandMode.move;
  final Map<String, String> animationStates = <String, String>{};
  final Map<String, CharacterFacing> unitFacings = <String, CharacterFacing>{};
  final Map<String, GridPoint> _visualUnitPositions = <String, GridPoint>{};
  final Map<String, Timer> _animationResetTimers = <String, Timer>{};
  final List<_BattleFloatingTextEntry> _floatingTexts =
      <_BattleFloatingTextEntry>[];
  final Map<String, Timer> _floatingTextTimers = <String, Timer>{};
  final List<_BattleParticleEntry> _particles = <_BattleParticleEntry>[];
  final Map<String, Timer> _particleTimers = <String, Timer>{};
  int _floatingTextSequence = 0;
  int _particleSequence = 0;
  int _movementSequence = 0;
  bool _didInitialize = false;
  bool _isAnimatingMovement = false;

  static const Duration _movementStepDuration = Duration(milliseconds: 140);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) {
      return;
    }
    _initializeBattleState();
    _didInitialize = true;
  }

  @override
  void dispose() {
    for (final timer in _animationResetTimers.values) {
      timer.cancel();
    }
    _animationResetTimers.clear();
    for (final timer in _floatingTextTimers.values) {
      timer.cancel();
    }
    _floatingTextTimers.clear();
    for (final timer in _particleTimers.values) {
      timer.cancel();
    }
    _particleTimers.clear();
    super.dispose();
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
        state.units
            .where((unit) => unit.active)
            .map((unit) => MapEntry(unit.id, 'idle')),
      );
    unitFacings
      ..clear()
      ..addEntries(
        state.units
            .where((unit) => unit.active)
            .map(
              (unit) => MapEntry(unit.id, CharacterSpriteAssets.defaultFacing),
            ),
      );
    _visualUnitPositions
      ..clear()
      ..addEntries(
        state.units
            .where((unit) => unit.active)
            .map((unit) => MapEntry(unit.id, unit.position)),
      );
    for (final timer in _animationResetTimers.values) {
      timer.cancel();
    }
    _animationResetTimers.clear();
    for (final timer in _floatingTextTimers.values) {
      timer.cancel();
    }
    _floatingTextTimers.clear();
    _floatingTexts.clear();
    for (final timer in _particleTimers.values) {
      timer.cancel();
    }
    _particleTimers.clear();
    _particles.clear();
    _isAnimatingMovement = false;
  }

  void _setAnimation(
    String unitId,
    String animationState, {
    CharacterFacing? facing,
  }) {
    animationStates[unitId] = animationState;
    if (facing != null) {
      unitFacings[unitId] = facing;
    }
  }

  void _scheduleIdleReset(
    Iterable<String> unitIds, {
    Duration delay = const Duration(milliseconds: 700),
  }) {
    for (final unitId in unitIds.toSet()) {
      _animationResetTimers.remove(unitId)?.cancel();
      _animationResetTimers[unitId] = Timer(delay, () {
        if (!mounted) {
          return;
        }
        setState(() {
          animationStates[unitId] = 'idle';
        });
        _animationResetTimers.remove(unitId);
      });
    }
  }

  void _spawnFloatingText(BattleUnit unit, int amount, _BattleFloatTone tone) {
    if (amount <= 0) {
      return;
    }
    final entry = _BattleFloatingTextEntry(
      id: 'float-${_floatingTextSequence++}',
      position: unit.position,
      text: tone == _BattleFloatTone.damage ? '-$amount' : '+$amount',
      tone: tone,
    );
    setState(() {
      _floatingTexts.add(entry);
    });
    _floatingTextTimers[entry.id]?.cancel();
    _floatingTextTimers[entry.id] = Timer(
      const Duration(milliseconds: 950),
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _floatingTexts.removeWhere((candidate) => candidate.id == entry.id);
        });
        _floatingTextTimers.remove(entry.id);
      },
    );
  }

  void _emitBattleDeltaTexts(BattleState previousState, BattleState nextState) {
    for (final nextUnit in nextState.units) {
      final previousUnit = previousState.units.firstWhereOrNull(
        (candidate) => candidate.id == nextUnit.id,
      );
      if (previousUnit == null) {
        continue;
      }
      final delta = nextUnit.hp - previousUnit.hp;
      if (delta < 0) {
        _spawnFloatingText(nextUnit, -delta, _BattleFloatTone.damage);
      } else if (delta > 0) {
        _spawnFloatingText(nextUnit, delta, _BattleFloatTone.heal);
      }
    }
  }

  void _spawnParticle(GridPoint position, _BattleParticleKind kind) {
    final entry = _BattleParticleEntry(
      id: 'particle-${_particleSequence++}',
      position: position,
      kind: kind,
    );
    setState(() {
      _particles.add(entry);
    });
    _particleTimers[entry.id]?.cancel();
    _particleTimers[entry.id] = Timer(const Duration(milliseconds: 820), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _particles.removeWhere((candidate) => candidate.id == entry.id);
      });
      _particleTimers.remove(entry.id);
    });
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

  Future<void> _selectUnit(String unitId, {bool openMenu = true}) async {
    setState(() {
      selectedUnitId = unitId;
      commandMode = PlayerCommandMode.move;
    });
    if (openMenu && mounted) {
      await _showCommandMenu(unitId);
    }
  }

  Future<void> _showCommandMenu(String unitId) async {
    final unit = state.units.firstWhere(
      (candidate) => candidate.id == unitId,
      orElse: () => _selectedUnit,
    );
    final canAct =
        !unit.turnState.hasActed && state.outcome == BattleOutcome.ongoing;
    final action = await showModalBottomSheet<_BattleMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        Widget menuTile(
          _BattleMenuAction action,
          String label,
          String subtitle,
        ) {
          return ListTile(
            enabled: canAct,
            title: Text(label),
            subtitle: Text(subtitle),
            onTap: canAct ? () => Navigator.of(context).pop(action) : null,
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('${unit.name} 행동 선택'),
                subtitle: Text(
                  canAct
                      ? '명령을 고른 뒤 전장 타일이나 목표 유닛을 직접 누르세요.'
                      : '이미 행동을 마친 유닛이라 새 명령을 줄 수 없습니다.',
                ),
              ),
              menuTile(_BattleMenuAction.move, '이동', '이동 가능한 타일이 전장에 강조됩니다.'),
              menuTile(
                _BattleMenuAction.attack,
                '공격',
                '붉게 강조된 적 유닛을 전장에서 직접 선택합니다.',
              ),
              menuTile(
                _BattleMenuAction.tactic,
                '책략',
                '책략 대상 유닛을 전장에서 직접 선택합니다.',
              ),
              menuTile(
                _BattleMenuAction.item,
                '도구',
                '도구 대상 아군을 전장에서 직접 선택합니다.',
              ),
              menuTile(_BattleMenuAction.wait, '대기', '즉시 행동을 종료합니다.'),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _BattleMenuAction.move:
        setState(() => commandMode = PlayerCommandMode.move);
        return;
      case _BattleMenuAction.attack:
        setState(() => commandMode = PlayerCommandMode.attack);
        return;
      case _BattleMenuAction.tactic:
        setState(() => commandMode = PlayerCommandMode.tactic);
        return;
      case _BattleMenuAction.item:
        setState(() => commandMode = PlayerCommandMode.item);
        return;
      case _BattleMenuAction.wait:
        _waitSelected();
        return;
    }
  }

  List<GridPoint> _movementPath(BattleUnit unit, GridPoint destination) {
    final queue = <GridPoint>[unit.position];
    final previous = <GridPoint, GridPoint?>{unit.position: null};

    Iterable<GridPoint> neighbors(GridPoint point) sync* {
      yield GridPoint(point.x + 1, point.y);
      yield GridPoint(point.x - 1, point.y);
      yield GridPoint(point.x, point.y + 1);
      yield GridPoint(point.x, point.y - 1);
    }

    bool inBounds(GridPoint point) =>
        point.x >= 0 &&
        point.y >= 0 &&
        point.x < state.stage.width &&
        point.y < state.stage.height;

    bool occupied(GridPoint point) => state.units.any(
      (candidate) =>
          candidate.active &&
          candidate.id != unit.id &&
          candidate.position == point,
    );

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == destination) {
        break;
      }

      for (final next in neighbors(current)) {
        if (!inBounds(next)) {
          continue;
        }
        if (previous.containsKey(next)) {
          continue;
        }
        if (!BattleEngine.terrainAt(state, next.x, next.y).passable) {
          continue;
        }
        if (occupied(next)) {
          continue;
        }
        previous[next] = current;
        queue.add(next);
      }
    }

    if (!previous.containsKey(destination)) {
      return [unit.position, destination];
    }

    final path = <GridPoint>[];
    GridPoint? current = destination;
    while (current != null) {
      path.add(current);
      current = previous[current];
    }
    return path.reversed.toList(growable: false);
  }

  Future<void> _moveSelected(GridPoint destination) async {
    if (_isAnimatingMovement) {
      return;
    }
    final selectedId = _selectedUnit.id;
    final unit = _selectedUnit;
    final path = _movementPath(unit, destination);
    final sequence = ++_movementSequence;
    final session = InheritedGameSession.of(context);

    setState(() {
      _isAnimatingMovement = true;
      _setAnimation(
        selectedId,
        'walk',
        facing: unitFacings[selectedId] ?? CharacterSpriteAssets.defaultFacing,
      );
    });

    GridPoint previousPoint = unit.position;
    for (final step in path.skip(1)) {
      if (!mounted || sequence != _movementSequence) {
        return;
      }
      final facing = CharacterSpriteAssets.facingFromPoints(
        previousPoint,
        step,
        fallback:
            unitFacings[selectedId] ?? CharacterSpriteAssets.defaultFacing,
      );
      setState(() {
        _visualUnitPositions[selectedId] = step;
        _setAnimation(selectedId, 'walk', facing: facing);
      });
      previousPoint = step;
      await Future<void>.delayed(_movementStepDuration);
    }

    if (!mounted || sequence != _movementSequence) {
      return;
    }

    final nextState = BattleEngine.moveUnit(
      state,
      unitId: selectedId,
      destination: destination,
    );

    setState(() {
      state = nextState;
      session.updateCurrentBattle(state);
      _visualUnitPositions[selectedId] = nextState
          .unitById(selectedId)
          .position;
      _isAnimatingMovement = false;
    });
    _scheduleIdleReset([selectedId], delay: const Duration(milliseconds: 250));
  }

  void _attackSelected(String targetId) {
    if (_isAnimatingMovement) {
      return;
    }
    final previousState = state;
    final selectedId = _selectedUnit.id;
    final target = state.unitById(targetId);
    final attackerFacing = CharacterSpriteAssets.facingFromPoints(
      _selectedUnit.position,
      target.position,
      fallback: unitFacings[selectedId] ?? CharacterSpriteAssets.defaultFacing,
    );
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.attackUnit(
        state,
        attackerId: selectedId,
        targetId: targetId,
      );
      session.updateCurrentBattle(state);
      _setAnimation(selectedId, 'attack', facing: attackerFacing);
      _setAnimation(targetId, 'hit', facing: attackerFacing.opposite);
      _spawnParticle(target.position, _BattleParticleKind.attack);
    });
    _emitBattleDeltaTexts(previousState, state);
    _scheduleIdleReset([selectedId, targetId]);
  }

  void _tacticSelected(String targetId) {
    if (_isAnimatingMovement) {
      return;
    }
    final previousState = state;
    final selectedId = _selectedUnit.id;
    final target = state.unitById(targetId);
    final casterFacing = CharacterSpriteAssets.facingFromPoints(
      _selectedUnit.position,
      target.position,
      fallback: unitFacings[selectedId] ?? CharacterSpriteAssets.defaultFacing,
    );
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.useTactic(
        state,
        casterId: selectedId,
        targetId: targetId,
      );
      session.updateCurrentBattle(state);
      _setAnimation(selectedId, 'attack', facing: casterFacing);
      _setAnimation(targetId, 'hit', facing: casterFacing.opposite);
      _spawnParticle(target.position, _BattleParticleKind.tactic);
      commandMode = PlayerCommandMode.move;
    });
    _emitBattleDeltaTexts(previousState, state);
    _scheduleIdleReset([selectedId, targetId]);
  }

  void _itemSelected(String targetId) {
    if (_isAnimatingMovement) {
      return;
    }
    final previousState = state;
    final selectedId = _selectedUnit.id;
    final target = state.unitById(targetId);
    final facing = CharacterSpriteAssets.facingFromPoints(
      _selectedUnit.position,
      target.position,
      fallback: unitFacings[selectedId] ?? CharacterSpriteAssets.defaultFacing,
    );
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.useItem(
        state,
        userId: selectedId,
        targetId: targetId,
      );
      session.updateCurrentBattle(state);
      _setAnimation(selectedId, 'idle', facing: facing);
      commandMode = PlayerCommandMode.move;
    });
    _emitBattleDeltaTexts(previousState, state);
  }

  void _waitSelected() {
    if (_isAnimatingMovement) {
      return;
    }
    final selectedId = _selectedUnit.id;
    final session = InheritedGameSession.of(context);
    setState(() {
      state = BattleEngine.waitUnit(state, unitId: selectedId);
      session.updateCurrentBattle(state);
      animationStates[selectedId] = 'idle';
      commandMode = PlayerCommandMode.move;
    });
  }

  void _selectInteractiveTarget(String unitId) {
    if (_isAnimatingMovement) {
      return;
    }
    switch (commandMode) {
      case PlayerCommandMode.attack:
        _attackSelected(unitId);
        return;
      case PlayerCommandMode.tactic:
        _tacticSelected(unitId);
        return;
      case PlayerCommandMode.item:
        _itemSelected(unitId);
        return;
      case PlayerCommandMode.move:
        return;
    }
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
          onPressed: _isAnimatingMovement
              ? null
              : state.outcome == BattleOutcome.ongoing
              ? _endTurn
              : _reset,
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
              animationStates: animationStates,
              unitFacings: unitFacings,
              visualUnitPositions: _visualUnitPositions,
              floatingTexts: _floatingTexts,
              particles: _particles,
              highlightedTiles: commandMode == PlayerCommandMode.move
                  ? reachableTiles.toSet()
                  : <GridPoint>{},
              interactiveTargetUnitIds: switch (commandMode) {
                PlayerCommandMode.attack =>
                  attackableEnemies.map((unit) => unit.id).toSet(),
                PlayerCommandMode.tactic =>
                  tacticTargets.map((unit) => unit.id).toSet(),
                PlayerCommandMode.item =>
                  itemTargets.map((unit) => unit.id).toSet(),
                PlayerCommandMode.move => <String>{},
              },
              onUnitSelected: (unitId) {
                if (!_isAnimatingMovement) {
                  _selectUnit(unitId);
                }
              },
              onTileSelected: _moveSelected,
              onTargetUnitSelected: _selectInteractiveTarget,
              interactionLocked: _isAnimatingMovement,
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
                        onSelected: _isAnimatingMovement
                            ? null
                            : (_) {
                                _selectUnit(unit.id);
                              },
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
                      facing:
                          unitFacings[selectedUnit.id] ??
                          CharacterSpriteAssets.defaultFacing,
                      size: 72,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('애니메이션 상태: $selectedAnimation'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed:
                                !_isAnimatingMovement &&
                                    state.outcome == BattleOutcome.ongoing
                                ? () => _showCommandMenu(selectedUnit.id)
                                : null,
                            child: const Text('행동 선택'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('고유 강점: ${selectedUnit.signature}'),
                const SizedBox(height: 8),
                Text(switch (commandMode) {
                  _ when _isAnimatingMovement => '현재 모드: 이동 연출 진행 중',
                  PlayerCommandMode.attack =>
                    '현재 모드: 공격 목표 선택 (${attackableEnemies.length}명 가능)',
                  PlayerCommandMode.tactic =>
                    '현재 모드: 책략 목표 선택 (${tacticTargets.length}명 가능)',
                  PlayerCommandMode.item =>
                    '현재 모드: 도구 대상 선택 (${itemTargets.length}명 가능)',
                  PlayerCommandMode.move =>
                    '현재 모드: 이동 지점 선택 (${reachableTiles.length}칸 가능)',
                }),
                const SizedBox(height: 4),
                Text(switch (commandMode) {
                  _ when _isAnimatingMovement => '이동 애니메이션이 끝날 때까지 입력이 잠깁니다.',
                  PlayerCommandMode.attack => '붉게 강조된 적 유닛을 전장에서 직접 누르세요.',
                  PlayerCommandMode.tactic => '강조된 목표를 전장에서 직접 눌러 책략을 실행하세요.',
                  PlayerCommandMode.item => '강조된 아군을 전장에서 직접 눌러 도구를 사용하세요.',
                  PlayerCommandMode.move => '밝게 강조된 이동 가능 타일을 전장에서 직접 누르세요.',
                }),
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
