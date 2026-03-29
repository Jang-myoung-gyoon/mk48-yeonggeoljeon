import 'dart:math';

import 'models.dart';

class BattleEngine {
  const BattleEngine._();

  static BattleState createInitialState(StageDefinition stage) {
    final units = [
      ...stage.playerUnits.map(BattleUnit.fromPlacement),
      ...stage.enemyUnits.map(BattleUnit.fromPlacement),
    ];
    return BattleState(
      stage: stage,
      turn: 1,
      phase: BattlePhase.player,
      units: units,
      log: ['${stage.name} 개전 — ${stage.objective}'],
      outcome: BattleOutcome.ongoing,
    );
  }

  static TerrainType terrainAt(BattleState state, int x, int y) {
    return state.stage.tiles
        .firstWhere((tile) => tile.x == x && tile.y == y)
        .type;
  }

  static List<GridPoint> reachableTiles(BattleState state, Object unitOrId) {
    final unit = _resolveUnit(state, unitOrId);
    if (unit == null || !unit.alive) return const [];

    final visited = <GridPoint, int>{unit.position: 0};
    final frontier = <GridPoint>[unit.position];

    while (frontier.isNotEmpty) {
      final current = frontier.removeAt(0);
      final distance = visited[current]!;
      if (distance >= unit.mobility) continue;

      for (final next in _neighbors(current)) {
        if (!_inBounds(state.stage, next.x, next.y)) continue;
        if (!terrainAt(state, next.x, next.y).passable) continue;
        if (_occupied(state, next.x, next.y, exceptId: unit.id)) continue;
        if (visited.containsKey(next)) continue;
        visited[next] = distance + 1;
        frontier.add(next);
      }
    }

    final tiles = visited.keys.toList(growable: false)
      ..sort((a, b) {
        final byY = a.y.compareTo(b.y);
        return byY != 0 ? byY : a.x.compareTo(b.x);
      });
    return tiles;
  }

  static List<BattleUnit> attackableTargets(
    BattleState state,
    Object unitOrId,
  ) {
    final unit = _resolveUnit(state, unitOrId);
    if (unit == null || !unit.alive) return const [];
    return state.units
        .where(
          (candidate) =>
              candidate.alive &&
              candidate.faction != unit.faction &&
              _distance(unit.position, candidate.position) <= unit.range,
        )
        .toList(growable: false);
  }

  static List<BattleUnit> tacticTargets(
    BattleState state,
    Object unitOrId,
  ) {
    final unit = _resolveUnit(state, unitOrId);
    if (unit == null || !unit.alive) return const [];
    return state.units
        .where(
          (candidate) =>
              candidate.alive &&
              candidate.faction != unit.faction &&
              _distance(unit.position, candidate.position) <= unit.range + 1,
        )
        .toList(growable: false);
  }

  static List<BattleUnit> itemTargets(
    BattleState state,
    Object unitOrId,
  ) {
    final unit = _resolveUnit(state, unitOrId);
    if (unit == null || !unit.alive) return const [];
    return state.units
        .where(
          (candidate) =>
              candidate.alive &&
              candidate.faction == unit.faction &&
              candidate.hp < candidate.maxHp &&
              _distance(unit.position, candidate.position) <= 1,
        )
        .toList(growable: false);
  }

  static BattleState moveUnit(
    BattleState state, {
    required String unitId,
    required GridPoint destination,
  }) {
    _validateMove(state, unitId, destination);
    return applyPlayerCommand(
      state,
      MoveUnitCommand(unitId: unitId, destination: destination),
    );
  }

  static BattleState attackUnit(
    BattleState state, {
    required String attackerId,
    required String targetId,
  }) {
    _validateAttack(state, attackerId, targetId);
    return applyPlayerCommand(
      state,
      AttackUnitCommand(attackerId: attackerId, targetId: targetId),
    );
  }

  static BattleState useTactic(
    BattleState state, {
    required String casterId,
    required String targetId,
  }) {
    _validateTactic(state, casterId, targetId);
    return applyPlayerCommand(
      state,
      UseTacticCommand(casterId: casterId, targetId: targetId),
    );
  }

  static BattleState useItem(
    BattleState state, {
    required String userId,
    required String targetId,
  }) {
    _validateItem(state, userId, targetId);
    return applyPlayerCommand(
      state,
      UseItemCommand(userId: userId, targetId: targetId),
    );
  }

  static BattleState waitUnit(BattleState state, {required String unitId}) {
    _validatePlayerActionPhase(state, unitId);
    return applyPlayerCommand(state, WaitUnitCommand(unitId: unitId));
  }

  static BattleState endPlayerTurn(BattleState state) {
    return applyPlayerCommand(state, const EndTurnCommand());
  }

  static BattleState applyPlayerCommand(
    BattleState state,
    PlayerCommand command,
  ) {
    if (state.outcome != BattleOutcome.ongoing) return state;

    return switch (command) {
      MoveUnitCommand() => _movePlayerUnit(state, command),
      AttackUnitCommand() => _attackWithPlayer(state, command),
      UseTacticCommand() => _useTactic(state, command),
      UseItemCommand() => _useItem(state, command),
      WaitUnitCommand() => _waitPlayerUnit(state, command),
      EndTurnCommand() => _endPlayerTurn(state),
      _ => state,
    };
  }

  static BattleState runFullRound(BattleState state, {int seed = 0}) {
    var working = state;
    if (working.outcome != BattleOutcome.ongoing) return working;

    working = _runAiPhase(
      working.copyWith(phase: BattlePhase.player),
      Faction.shu,
      seed: seed,
    );
    if (working.outcome != BattleOutcome.ongoing) return working;

    working = _runAiPhase(
      working.copyWith(phase: BattlePhase.enemy),
      Faction.enemy,
      seed: seed + 1,
    );
    if (working.outcome != BattleOutcome.ongoing) return working;

    return _startNextTurn(working);
  }

  static SimulationReport simulate(StageDefinition stage, {int seed = 7}) {
    var state = createInitialState(stage);
    var rounds = 0;
    while (state.outcome == BattleOutcome.ongoing &&
        rounds <= stage.turnLimit) {
      state = runFullRound(state, seed: seed + rounds);
      rounds++;
    }

    return SimulationReport(
      outcome: state.outcome,
      turnsUsed: state.turn,
      stageName: stage.name,
      log: state.log,
      survivors: state.units
          .where((unit) => unit.alive)
          .toList(growable: false),
    );
  }

  static BattleState _movePlayerUnit(
    BattleState state,
    MoveUnitCommand command,
  ) {
    if (state.phase != BattlePhase.player) {
      return _appendLog(state, '지금은 아군 수동 이동을 할 수 없는 위상입니다.');
    }

    final unit = _resolveUnit(state, command.unitId);
    if (!_isControllablePlayer(unit)) {
      return _appendLog(state, '이동 가능한 아군을 찾지 못했습니다.');
    }
    if (unit!.turnState.hasMoved || unit.turnState.hasActed) {
      return _appendLog(state, '${unit.name}은(는) 이미 이동을 완료했습니다.');
    }

    final reachable = reachableTiles(state, unit);
    if (!reachable.contains(command.destination)) {
      return _appendLog(state, '${unit.name}은(는) 해당 위치로 이동할 수 없습니다.');
    }

    final moved = unit.copyWith(
      x: command.destination.x,
      y: command.destination.y,
      turnState: unit.turnState.copyWith(hasMoved: true),
    );
    return _replaceUnit(
      state,
      moved,
      '${unit.name} 이동 → (${command.destination.x}, ${command.destination.y})',
    );
  }

  static BattleState _attackWithPlayer(
    BattleState state,
    AttackUnitCommand command,
  ) {
    if (state.phase != BattlePhase.player) {
      return _appendLog(state, '지금은 아군 수동 공격을 할 수 없는 위상입니다.');
    }

    final attacker = _resolveUnit(state, command.attackerId);
    final target = _resolveUnit(state, command.targetId);
    if (!_isControllablePlayer(attacker) ||
        target == null ||
        !target.alive ||
        target.faction == attacker!.faction) {
      return _appendLog(state, '유효한 공격 대상을 찾지 못했습니다.');
    }
    if (attacker.turnState.hasActed) {
      return _appendLog(state, '${attacker.name}은(는) 이미 행동을 마쳤습니다.');
    }
    if (_distance(attacker.position, target.position) > attacker.range) {
      return _appendLog(
        state,
        '${target.name}은(는) ${attacker.name}의 사거리 밖에 있습니다.',
      );
    }

    final damage = _damageForAttack(state, attacker, target);
    final resolvedTarget = target.copyWith(hp: max(0, target.hp - damage));
    final resolvedAttacker = attacker.copyWith(
      turnState: attacker.turnState.copyWith(hasActed: true),
    );

    var updated = _replaceUnitInList(state.units, resolvedTarget);
    updated = _replaceUnitInList(updated, resolvedAttacker);
    final next = state.copyWith(
      units: updated,
      log: [
        ...state.log,
        '${resolvedAttacker.name} → ${resolvedTarget.name} $damage피해 (${resolvedTarget.hp}/${resolvedTarget.maxHp})',
      ],
    );
    return next.copyWith(outcome: _evaluateOutcome(next));
  }

  static BattleState _waitPlayerUnit(
    BattleState state,
    WaitUnitCommand command,
  ) {
    final unit = _resolveUnit(state, command.unitId);
    if (!_isControllablePlayer(unit)) {
      return _appendLog(state, '대기 가능한 아군을 찾지 못했습니다.');
    }

    final updated = unit!.copyWith(
      turnState: unit.turnState.copyWith(hasActed: true),
    );
    return _replaceUnit(state, updated, '${unit.name} 대기');
  }

  static BattleState _useTactic(
    BattleState state,
    UseTacticCommand command,
  ) {
    if (state.phase != BattlePhase.player) {
      return _appendLog(state, '지금은 아군 책략을 사용할 수 없는 위상입니다.');
    }

    final caster = _resolveUnit(state, command.casterId);
    final target = _resolveUnit(state, command.targetId);
    if (!_isControllablePlayer(caster) ||
        target == null ||
        !target.alive ||
        target.faction == caster!.faction) {
      return _appendLog(state, '유효한 책략 대상을 찾지 못했습니다.');
    }
    if (caster.turnState.hasActed) {
      return _appendLog(state, '${caster.name}은(는) 이미 행동을 마쳤습니다.');
    }
    if (_distance(caster.position, target.position) > caster.range + 1) {
      return _appendLog(state, '${target.name}은(는) 책략 사거리 밖에 있습니다.');
    }

    final damage = max(2, caster.attack + 2 - (target.defense ~/ 2));
    final resolvedTarget = target.copyWith(hp: max(0, target.hp - damage));
    final resolvedCaster = caster.copyWith(
      turnState: caster.turnState.copyWith(hasActed: true),
    );

    var updated = _replaceUnitInList(state.units, resolvedTarget);
    updated = _replaceUnitInList(updated, resolvedCaster);
    final next = state.copyWith(
      units: updated,
      log: [
        ...state.log,
        '${resolvedCaster.name} 책략 → ${resolvedTarget.name} $damage피해 (${resolvedTarget.hp}/${resolvedTarget.maxHp})',
      ],
    );
    return next.copyWith(outcome: _evaluateOutcome(next));
  }

  static BattleState _useItem(
    BattleState state,
    UseItemCommand command,
  ) {
    if (state.phase != BattlePhase.player) {
      return _appendLog(state, '지금은 도구를 사용할 수 없는 위상입니다.');
    }

    final user = _resolveUnit(state, command.userId);
    final target = _resolveUnit(state, command.targetId);
    if (!_isControllablePlayer(user) ||
        target == null ||
        !target.alive ||
        target.faction != user!.faction) {
      return _appendLog(state, '유효한 도구 대상을 찾지 못했습니다.');
    }
    if (user.turnState.hasActed) {
      return _appendLog(state, '${user.name}은(는) 이미 행동을 마쳤습니다.');
    }
    if (_distance(user.position, target.position) > 1) {
      return _appendLog(state, '${target.name}은(는) 도구 사용 범위 밖에 있습니다.');
    }

    final healedTarget = target.copyWith(
      hp: min(target.maxHp, target.hp + 5),
    );
    final resolvedUser = user.copyWith(
      turnState: user.turnState.copyWith(hasActed: true),
    );

    var updated = _replaceUnitInList(state.units, healedTarget);
    updated = _replaceUnitInList(updated, resolvedUser);
    final restored = healedTarget.hp - target.hp;
    final next = state.copyWith(
      units: updated,
      log: [
        ...state.log,
        '${resolvedUser.name} 도구 → ${healedTarget.name} $restored회복 (${healedTarget.hp}/${healedTarget.maxHp})',
      ],
    );
    return next.copyWith(outcome: _evaluateOutcome(next));
  }

  static BattleState _endPlayerTurn(BattleState state) {
    var working = state;
    if (working.outcome != BattleOutcome.ongoing) return working;
    working = _runAiPhase(
      working.copyWith(phase: BattlePhase.enemy),
      Faction.enemy,
      seed: working.turn * 31,
    );
    if (working.outcome != BattleOutcome.ongoing) return working;
    return _startNextTurn(working);
  }

  static BattleState _runAiPhase(
    BattleState state,
    Faction faction, {
    required int seed,
  }) {
    var working = state;
    final actors = working.livingUnits(faction);

    for (final actor in actors) {
      final currentActor = _resolveUnit(working, actor.id);
      if (currentActor == null ||
          !currentActor.alive ||
          currentActor.turnState.hasActed) {
        continue;
      }

      final target = _pickTarget(working, currentActor, seed: seed);
      if (target == null) continue;

      var actedActor = currentActor;
      var updatedUnits = [...working.units];
      if (_distance(actedActor.position, target.position) > actedActor.range) {
        final moved = _moveToward(working, actedActor, target);
        actedActor = moved;
        updatedUnits = _replaceUnitInList(updatedUnits, moved);
      }

      final refreshedTarget =
          updatedUnits.where((unit) => unit.id == target.id).firstOrNull;

      if (refreshedTarget != null &&
          refreshedTarget.alive &&
          _distance(actedActor.position, refreshedTarget.position) <=
              actedActor.range) {
        final damage = _damageForAttack(
          working.copyWith(units: updatedUnits),
          actedActor,
          refreshedTarget,
        );
        final resolvedTarget = refreshedTarget.copyWith(
          hp: max(0, refreshedTarget.hp - damage),
        );
        final resolvedActor = actedActor.copyWith(
          turnState: actedActor.turnState.copyWith(
            hasMoved: true,
            hasActed: true,
          ),
        );
        updatedUnits = _replaceUnitInList(updatedUnits, resolvedTarget);
        updatedUnits = _replaceUnitInList(updatedUnits, resolvedActor);
        working = working.copyWith(
          units: updatedUnits,
          log: [
            ...working.log,
            '${resolvedActor.name} → ${resolvedTarget.name} $damage피해 (${resolvedTarget.hp}/${resolvedTarget.maxHp})',
          ],
        );
      } else {
        final resolvedActor = actedActor.copyWith(
          turnState: actedActor.turnState.copyWith(
            hasMoved: true,
            hasActed: true,
          ),
        );
        updatedUnits = _replaceUnitInList(updatedUnits, resolvedActor);
        working = working.copyWith(
          units: updatedUnits,
          log: [...working.log, '${resolvedActor.name} 이동 후 대기'],
        );
      }

      final outcome = _evaluateOutcome(working);
      if (outcome != BattleOutcome.ongoing) {
        return working.copyWith(outcome: outcome);
      }
    }

    return working.copyWith(outcome: _evaluateOutcome(working));
  }

  static BattleOutcome _evaluateOutcome(BattleState state) {
    final heroes = state.livingUnits(Faction.shu);
    final enemies = state.livingUnits(Faction.enemy);
    final lordAlive = heroes.any((unit) => unit.isLord);
    final bossAlive = enemies.any((unit) => unit.isBoss);

    if (!lordAlive) return BattleOutcome.defeat;
    if (enemies.isEmpty || !bossAlive) return BattleOutcome.victory;
    if (state.turn > state.stage.turnLimit) return BattleOutcome.defeat;
    return BattleOutcome.ongoing;
  }

  static BattleUnit? _pickTarget(
    BattleState state,
    BattleUnit actor, {
    required int seed,
  }) {
    final candidates = state.units
        .where((unit) => unit.faction != actor.faction && unit.alive)
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    final ranked = [...candidates]
      ..sort((a, b) {
        final scoreCompare = _targetScore(
          state,
          actor,
          b,
        ).compareTo(_targetScore(state, actor, a));
        if (scoreCompare != 0) return scoreCompare;
        return a.id.compareTo(b.id);
      });
    return ranked.first;
  }

  static int _targetScore(
    BattleState state,
    BattleUnit actor,
    BattleUnit target,
  ) {
    final distance = _distance(actor.position, target.position);
    var score = 20 - distance;
    score += target.isBoss ? 6 : 0;
    score += target.hp <= actor.attack ? 5 : 0;
    score += target.isLord ? 4 : 0;
    score -= terrainAt(state, target.x, target.y).defenseBonus;
    return score;
  }

  static BattleUnit _moveToward(
    BattleState state,
    BattleUnit actor,
    BattleUnit target,
  ) {
    final destinations = reachableTiles(state, actor);
    final ranked = [...destinations]
      ..sort((a, b) {
        final scoreCompare = _moveScore(
          state,
          actor,
          target,
          b,
        ).compareTo(_moveScore(state, actor, target, a));
        if (scoreCompare != 0) return scoreCompare;
        final byY = a.y.compareTo(b.y);
        return byY != 0 ? byY : a.x.compareTo(b.x);
      });

    final destination = ranked.first;
    return actor.copyWith(
      x: destination.x,
      y: destination.y,
      turnState: actor.turnState.copyWith(hasMoved: true),
    );
  }

  static int _moveScore(
    BattleState state,
    BattleUnit actor,
    BattleUnit target,
    GridPoint tile,
  ) {
    final terrain = terrainAt(state, tile.x, tile.y);
    final distanceScore = 12 - _distance(tile, target.position);
    final terrainScore =
        terrain.defenseBonus + (terrain == TerrainType.road ? 1 : 0);
    final aggressionBonus = actor.faction == Faction.enemy ? 1 : 0;
    return distanceScore + terrainScore + aggressionBonus;
  }

  static int _damageForAttack(
    BattleState state,
    BattleUnit attacker,
    BattleUnit target,
  ) {
    final terrainBonus = terrainAt(state, target.x, target.y).defenseBonus;
    return max(
      1,
      attacker.attack -
          target.defense +
          _classAdvantage(attacker, target) -
          terrainBonus,
    );
  }

  static int _classAdvantage(BattleUnit attacker, BattleUnit target) {
    if (attacker.unitClass == UnitClass.lancer &&
        target.unitClass == UnitClass.cavalry) {
      return 2;
    }
    if (attacker.unitClass == UnitClass.cavalry &&
        target.unitClass == UnitClass.archer) {
      return 2;
    }
    if (attacker.unitClass == UnitClass.guardian &&
        target.unitClass == UnitClass.raider) {
      return 1;
    }
    return 0;
  }

  static BattleState _startNextTurn(BattleState state) {
    final refreshedUnits = [
      for (final unit in state.units)
        unit.copyWith(turnState: UnitTurnState.idle),
    ];
    final next = state.copyWith(
      turn: state.turn + 1,
      phase: BattlePhase.player,
      units: refreshedUnits,
      log: [...state.log, '턴 ${state.turn} 종료'],
    );
    return next.copyWith(outcome: _evaluateOutcome(next));
  }

  static BattleState _replaceUnit(
    BattleState state,
    BattleUnit updatedUnit,
    String logLine,
  ) {
    final next = state.copyWith(
      units: _replaceUnitInList(state.units, updatedUnit),
      log: [...state.log, logLine],
    );
    return next.copyWith(outcome: _evaluateOutcome(next));
  }

  static List<BattleUnit> _replaceUnitInList(
    List<BattleUnit> units,
    BattleUnit updatedUnit,
  ) {
    return [
      for (final unit in units)
        if (unit.id == updatedUnit.id) updatedUnit else unit,
    ];
  }

  static BattleState _appendLog(BattleState state, String logLine) {
    return state.copyWith(log: [...state.log, logLine]);
  }

  static BattleUnit? _resolveUnit(BattleState state, Object unitOrId) {
    if (unitOrId is BattleUnit) {
      return state.units.where((unit) => unit.id == unitOrId.id).firstOrNull;
    }
    if (unitOrId is String) {
      return state.units.where((unit) => unit.id == unitOrId).firstOrNull;
    }
    return null;
  }

  static bool _isControllablePlayer(BattleUnit? unit) =>
      unit != null && unit.alive && unit.faction == Faction.shu;

  static BattleUnit _validatePlayerActionPhase(
    BattleState state,
    String unitId,
  ) {
    if (state.phase != BattlePhase.player) {
      throw ArgumentError('지금은 아군 수동 행동 위상이 아닙니다.');
    }

    final unit = _resolveUnit(state, unitId);
    if (!_isControllablePlayer(unit)) {
      throw ArgumentError('행동 가능한 아군을 찾지 못했습니다: $unitId');
    }
    return unit!;
  }

  static void _validateMove(
    BattleState state,
    String unitId,
    GridPoint destination,
  ) {
    final unit = _validatePlayerActionPhase(state, unitId);
    if (unit.turnState.hasMoved || unit.turnState.hasActed) {
      throw ArgumentError('${unit.name}은(는) 이미 이동을 완료했습니다.');
    }
    if (!reachableTiles(state, unit).contains(destination)) {
      throw ArgumentError('${unit.name}은(는) 해당 위치로 이동할 수 없습니다.');
    }
  }

  static void _validateAttack(
    BattleState state,
    String attackerId,
    String targetId,
  ) {
    final attacker = _validatePlayerActionPhase(state, attackerId);
    final target = _resolveUnit(state, targetId);
    if (target == null || !target.alive || target.faction == attacker.faction) {
      throw ArgumentError('유효한 공격 대상을 찾지 못했습니다: $targetId');
    }
    if (attacker.turnState.hasActed) {
      throw ArgumentError('${attacker.name}은(는) 이미 행동을 마쳤습니다.');
    }
    if (_distance(attacker.position, target.position) > attacker.range) {
      throw ArgumentError('${target.name}은(는) ${attacker.name}의 사거리 밖에 있습니다.');
    }
  }

  static void _validateTactic(
    BattleState state,
    String casterId,
    String targetId,
  ) {
    final caster = _validatePlayerActionPhase(state, casterId);
    final target = _resolveUnit(state, targetId);
    if (target == null || !target.alive || target.faction == caster.faction) {
      throw ArgumentError('유효한 책략 대상을 찾지 못했습니다: $targetId');
    }
    if (caster.turnState.hasActed) {
      throw ArgumentError('${caster.name}은(는) 이미 행동을 마쳤습니다.');
    }
    if (_distance(caster.position, target.position) > caster.range + 1) {
      throw ArgumentError('${target.name}은(는) ${caster.name}의 책략 사거리 밖에 있습니다.');
    }
  }

  static void _validateItem(
    BattleState state,
    String userId,
    String targetId,
  ) {
    final user = _validatePlayerActionPhase(state, userId);
    final target = _resolveUnit(state, targetId);
    if (target == null || !target.alive || target.faction != user.faction) {
      throw ArgumentError('유효한 도구 대상을 찾지 못했습니다: $targetId');
    }
    if (user.turnState.hasActed) {
      throw ArgumentError('${user.name}은(는) 이미 행동을 마쳤습니다.');
    }
    if (_distance(user.position, target.position) > 1) {
      throw ArgumentError('${target.name}은(는) ${user.name}의 도구 사용 범위 밖에 있습니다.');
    }
    if (target.hp >= target.maxHp) {
      throw ArgumentError('${target.name}은(는) 회복이 필요하지 않습니다.');
    }
  }

  static bool _inBounds(StageDefinition stage, int x, int y) =>
      x >= 0 && y >= 0 && x < stage.width && y < stage.height;

  static bool _occupied(BattleState state, int x, int y, {String? exceptId}) =>
      state.units.any(
        (unit) =>
            unit.alive && unit.id != exceptId && unit.x == x && unit.y == y,
      );

  static Iterable<GridPoint> _neighbors(GridPoint point) sync* {
    yield GridPoint(point.x + 1, point.y);
    yield GridPoint(point.x - 1, point.y);
    yield GridPoint(point.x, point.y + 1);
    yield GridPoint(point.x, point.y - 1);
  }

  static int _distance(GridPoint a, GridPoint b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();
}
