import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;
  final firstStage = repository.stages.first;
  final stage4 = repository.stages[3];
  final stage6 = repository.stages[5];
  final stage8 = repository.stages[7];
  final stage10 = repository.stages[9];

  test('reachable tiles stay within mobility and avoid impassable terrain', () {
    final state = BattleEngine.createInitialState(firstStage);
    final liuBei = state.units.firstWhere((unit) => unit.id == 'liu-bei');
    final reachable = BattleEngine.reachableTiles(state, liuBei);

    expect(reachable, contains(GridPoint(liuBei.x, liuBei.y)));
    expect(
      reachable
          .where((tile) => tile != GridPoint(liuBei.x, liuBei.y))
          .map((tile) => BattleEngine.terrainAt(state, tile.x, tile.y)),
      isNot(contains(anyOf(TerrainType.river, TerrainType.wall))),
    );
    expect(reachable, isNot(contains(const GridPoint(2, 2))));
  });

  test('finished states are returned unchanged by a full-round simulation', () {
    final state = BattleEngine.createInitialState(
      firstStage,
    ).copyWith(outcome: BattleOutcome.defeat);

    final next = BattleEngine.runFullRound(state, seed: 99);

    expect(next.turn, state.turn);
    expect(next.phase, state.phase);
    expect(next.outcome, BattleOutcome.defeat);
    expect(next.log, state.log);
  });

  test('manual move command only accepts legal reachable tiles', () {
    final state = BattleEngine.createInitialState(firstStage);
    final liuBei = state.units.firstWhere((unit) => unit.id == 'liu-bei');

    final moved = BattleEngine.moveUnit(
      state,
      unitId: liuBei.id,
      destination: const GridPoint(0, 1),
    );

    expect(moved.units.firstWhere((unit) => unit.id == liuBei.id).x, 0);
    expect(moved.units.firstWhere((unit) => unit.id == liuBei.id).y, 1);
    expect(
      () => BattleEngine.moveUnit(
        state,
        unitId: liuBei.id,
        destination: const GridPoint(6, 5),
      ),
      throwsArgumentError,
    );
  });

  test('manual attack command damages only in-range targets', () {
    final state = BattleEngine.createInitialState(firstStage);
    final liuBei = state.units.firstWhere((unit) => unit.id == 'liu-bei');
    final boss = state.units.firstWhere((unit) => unit.id == 'hua-xiong');
    final nearbyBoss = boss.copyWith(x: liuBei.x + 1, y: liuBei.y);
    final adjusted = state.copyWith(
      units: [
        for (final unit in state.units)
          if (unit.id == nearbyBoss.id) nearbyBoss else unit,
      ],
    );

    final attacked = BattleEngine.attackUnit(
      adjusted,
      attackerId: liuBei.id,
      targetId: nearbyBoss.id,
    );
    expect(
      attacked.units.firstWhere((unit) => unit.id == nearbyBoss.id).hp,
      lessThan(nearbyBoss.hp),
    );
    expect(
      attacked.units.firstWhere((unit) => unit.id == liuBei.id).hasActed,
      isTrue,
    );
    expect(
      () => BattleEngine.attackUnit(
        state,
        attackerId: liuBei.id,
        targetId: boss.id,
      ),
      throwsArgumentError,
    );
  });

  test('manual tactic command damages only valid targets in tactic range', () {
    final state = BattleEngine.createInitialState(firstStage);
    final strategist = state.units.firstWhere(
      (unit) => unit.id == 'zhuge-liang',
    );
    final boss = state.units.firstWhere((unit) => unit.id == 'hua-xiong');
    final nearbyBoss = boss.copyWith(x: strategist.x + 2, y: strategist.y);
    final adjusted = state.copyWith(
      units: [
        for (final unit in state.units)
          if (unit.id == nearbyBoss.id) nearbyBoss else unit,
      ],
    );

    final used = BattleEngine.useTactic(
      adjusted,
      casterId: strategist.id,
      targetId: nearbyBoss.id,
    );

    expect(
      used.units.firstWhere((unit) => unit.id == nearbyBoss.id).hp,
      lessThan(nearbyBoss.hp),
    );
    expect(
      used.units.firstWhere((unit) => unit.id == strategist.id).hasActed,
      isTrue,
    );
    expect(
      () => BattleEngine.useTactic(
        state,
        casterId: strategist.id,
        targetId: boss.id,
      ),
      throwsArgumentError,
    );
  });

  test('manual item command heals only injured adjacent allies', () {
    final state = BattleEngine.createInitialState(firstStage);
    final liuBei = state.units.firstWhere((unit) => unit.id == 'liu-bei');
    final injuredGuanYu = state.units
        .firstWhere((unit) => unit.id == 'guan-yu')
        .copyWith(x: liuBei.x + 1, y: liuBei.y, hp: 10);
    final adjusted = state.copyWith(
      units: [
        for (final unit in state.units)
          if (unit.id == injuredGuanYu.id) injuredGuanYu else unit,
      ],
    );

    final used = BattleEngine.useItem(
      adjusted,
      userId: liuBei.id,
      targetId: injuredGuanYu.id,
    );

    expect(
      used.units.firstWhere((unit) => unit.id == injuredGuanYu.id).hp,
      greaterThan(injuredGuanYu.hp),
    );
    expect(
      used.units.firstWhere((unit) => unit.id == liuBei.id).hasActed,
      isTrue,
    );
    expect(
      () => BattleEngine.useItem(state, userId: liuBei.id, targetId: 'guan-yu'),
      throwsArgumentError,
    );
  });

  test('ending the player turn advances enemy AI and the turn counter', () {
    final state = BattleEngine.createInitialState(firstStage);

    final next = BattleEngine.endPlayerTurn(state);

    expect(next.turn, 2);
    expect(next.phase, BattlePhase.player);
    expect(next.log.last, contains('턴 1 종료'));
  });

  test('exceeding the stage turn limit resolves to defeat immediately', () {
    final suddenDeathStage = firstStage.copyWith(
      turnLimit: 1,
      lossTriggers: const [
        StageLossRule(type: LossTriggerType.lordDead, description: '유비 격파'),
        StageLossRule(type: LossTriggerType.turnLimit, description: '1턴 초과', turnDeadline: 1),
      ],
    );
    final state = BattleEngine.createInitialState(suddenDeathStage);

    final next = BattleEngine.endPlayerTurn(state);

    expect(next.turn, 2);
    expect(next.outcome, BattleOutcome.defeat);
    expect(next.log.last, contains('턴 1 종료'));
  });

  test(
    'headless simulation resolves stage 1 deterministically for a fixed seed',
    () {
      final reportA = BattleEngine.simulate(firstStage, seed: 11);
      final reportB = BattleEngine.simulate(firstStage, seed: 11);

      expect(reportA.outcome, isNot(BattleOutcome.ongoing));
      expect(reportA.turnsUsed, lessThanOrEqualTo(firstStage.turnLimit + 1));
      expect(reportA.log, reportB.log);
      expect(
        reportA.survivors.map((unit) => unit.id),
        reportB.survivors.map((unit) => unit.id),
      );
    },
  );

  test('sample report is derived from the first stage simulation', () {
    final report = repository.sampleReport;

    expect(report.stageName, firstStage.name);
    expect(report.log.first, contains(firstStage.objective));
    expect(report.survivors, isNotEmpty);
  });

  test('stage 1, 4, 6, 8, 10 expose distinct executable objective types', () {
    expect(firstStage.objectiveType, StageObjectiveType.bossDefeat);
    expect(stage4.objectiveType, StageObjectiveType.escort);
    expect(stage6.objectiveType, StageObjectiveType.escape);
    expect(stage8.objectiveType, StageObjectiveType.holdPosition);
    expect(stage10.objectiveType, StageObjectiveType.capturePoints);
  });

  test('escort stages resolve victory when the tracked convoy reaches an escape zone', () {
    final state = BattleEngine.createInitialState(stage4);
    final escaped = state.units
        .map(
          (unit) => unit.id == 'xu-zhou-refugee'
              ? unit.copyWith(x: 8, y: 6)
              : unit,
        )
        .toList(growable: false);

    final next = BattleEngine.resolveState(state.copyWith(units: escaped));

    expect(next.outcome, BattleOutcome.victory);
  });

  test('escape stages resolve victory when enough tracked units have escaped', () {
    final state = BattleEngine.createInitialState(stage6);
    final escapedUnits = state.units
        .map(
          (unit) => ['liu-bei', 'guan-yu', 'zhang-fei', 'zhao-yun']
                  .contains(unit.id)
              ? unit.copyWith(x: 8, y: 0)
              : unit,
        )
        .toList(growable: false);

    final next = BattleEngine.resolveState(state.copyWith(units: escapedUnits));

    expect(next.outcome, BattleOutcome.victory);
  });

  test('hold-position stages resolve victory after the bridgehead is held long enough', () {
    final state = BattleEngine.createInitialState(stage8);
    final next = state.copyWith(
      turn: 3,
      captureStates: const {
        'changban-bridge': CapturePointState(
          pointId: 'changban-bridge',
          controller: Faction.shu,
          heldTurns: 2,
        ),
      },
    );

    expect(BattleEngine.evaluateOutcome(next), BattleOutcome.victory);
  });

  test('capture-point stages resolve victory when all required points are controlled', () {
    final state = BattleEngine.createInitialState(stage10);
    final next = state.copyWith(
      captureStates: const {
        'jing-north-gate': CapturePointState(
          pointId: 'jing-north-gate',
          controller: Faction.shu,
          heldTurns: 1,
        ),
        'jing-supply-depot': CapturePointState(
          pointId: 'jing-supply-depot',
          controller: Faction.shu,
          heldTurns: 1,
        ),
      },
    );

    expect(BattleEngine.evaluateOutcome(next), BattleOutcome.victory);
  });
}
