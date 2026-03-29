import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;
  final firstStage = repository.stages.first;

  BattleState stageState(int stageId) =>
      BattleEngine.createInitialState(repository.stages[stageId - 1]);

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
    final destination = BattleEngine.reachableTiles(
      state,
      liuBei,
    ).firstWhere((tile) => tile != liuBei.position);

    final moved = BattleEngine.moveUnit(
      state,
      unitId: liuBei.id,
      destination: destination,
    );

    expect(
      moved.units.firstWhere((unit) => unit.id == liuBei.id).position,
      destination,
    );
    expect(
      () => BattleEngine.moveUnit(
        state,
        unitId: liuBei.id,
        destination: const GridPoint(8, 6),
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
        StageLossRule(
          type: LossTriggerType.lordDead,
          description: '유비 격파',
          trackedUnitIds: ['liu-bei'],
        ),
        StageLossRule(
          type: LossTriggerType.turnLimit,
          description: '1턴 초과',
          turnDeadline: 1,
        ),
      ],
    );
    final state = BattleEngine.createInitialState(suddenDeathStage);

    final next = BattleEngine.endPlayerTurn(state);

    expect(next.turn, 2);
    expect(next.outcome, BattleOutcome.defeat);
    expect(next.log.last, contains('턴 1 종료'));
  });

  test(
    'stage 1 boss defeat objective resolves victory independently of enemy roster',
    () {
      final state = stageState(1);
      final defeatedBoss = state.units
          .firstWhere((unit) => unit.id == 'hua-xiong')
          .copyWith(hp: 0);
      final resolved = BattleEngine.resolveState(
        state.copyWith(
          units: [
            for (final unit in state.units)
              if (unit.id == 'hua-xiong') defeatedBoss else unit,
          ],
        ),
      );

      expect(resolved.outcome, BattleOutcome.victory);
    },
  );

  test(
    'stage 4 escort objective resolves when the refugee reaches the escape zone',
    () {
      final state = stageState(4);
      final refugee = state.units.firstWhere(
        (unit) => unit.id == 'xu-zhou-refugee',
      );
      final resolved = BattleEngine.resolveState(
        state.copyWith(
          units: [
            for (final unit in state.units)
              if (unit.id == refugee.id) refugee.copyWith(x: 8, y: 6) else unit,
          ],
        ),
      );

      expect(resolved.escapedUnitIds, contains('xu-zhou-refugee'));
      expect(resolved.outcome, BattleOutcome.victory);
    },
  );

  test(
    'stage 6 escape objective resolves when four heroes reach the retreat lane',
    () {
      final state = stageState(6);
      const escapeTiles = [
        GridPoint(8, 0),
        GridPoint(8, 1),
        GridPoint(8, 2),
        GridPoint(8, 3),
      ];
      final escapeIds = ['liu-bei', 'guan-yu', 'zhang-fei', 'zhao-yun'];
      final updatedUnits = [
        for (final unit in state.units)
          if (escapeIds.contains(unit.id))
            unit.copyWith(
              x: escapeTiles[escapeIds.indexOf(unit.id)].x,
              y: escapeTiles[escapeIds.indexOf(unit.id)].y,
            )
          else
            unit,
      ];

      final resolved = BattleEngine.resolveState(
        state.copyWith(units: updatedUnits),
      );

      expect(resolved.escapedUnitIds.where(escapeIds.contains), hasLength(4));
      expect(resolved.outcome, BattleOutcome.victory);
    },
  );

  test(
    'stage 8 hold position objective resolves after the bridge is held for two turns',
    () {
      final state = stageState(8);
      final liuBei = state.units.firstWhere((unit) => unit.id == 'liu-bei');
      final resolved = BattleEngine.resolveState(
        state.copyWith(
          units: [
            for (final unit in state.units)
              if (unit.id == liuBei.id) liuBei.copyWith(x: 4, y: 3) else unit,
          ],
          captureStates: const {
            'changban-bridge': CapturePointState(
              pointId: 'changban-bridge',
              controller: Faction.shu,
              heldTurns: 1,
            ),
          },
        ),
      );

      expect(resolved.captureStates['changban-bridge']?.heldTurns, 2);
      expect(resolved.outcome, BattleOutcome.victory);
    },
  );

  test(
    'stage 10 capture points objective resolves when both control points are occupied',
    () {
      final state = stageState(10);
      final liuBei = state.units.firstWhere((unit) => unit.id == 'liu-bei');
      final guanYu = state.units.firstWhere((unit) => unit.id == 'guan-yu');
      final resolved = BattleEngine.resolveState(
        state.copyWith(
          units: [
            for (final unit in state.units)
              if (unit.id == liuBei.id)
                liuBei.copyWith(x: 7, y: 2)
              else if (unit.id == guanYu.id)
                guanYu.copyWith(x: 6, y: 5)
              else if (unit.position == const GridPoint(6, 5))
                unit.copyWith(x: 5, y: 5)
              else
                unit,
          ],
        ),
      );

      expect(
        resolved.captureStates.values.where(
          (point) => point.controller == Faction.shu,
        ),
        hasLength(2),
      );
      expect(resolved.outcome, BattleOutcome.victory);
    },
  );

  test('npc death and escape failure loss triggers resolve defeat', () {
    final escortState = stageState(4);
    final deadEscort = BattleEngine.resolveState(
      escortState.copyWith(
        units: [
          for (final unit in escortState.units)
            if (unit.id == 'xu-zhou-refugee') unit.copyWith(hp: 0) else unit,
        ],
      ),
    );
    expect(deadEscort.outcome, BattleOutcome.defeat);

    final escapeState = BattleEngine.resolveState(
      stageState(6).copyWith(turn: 10),
    );
    expect(escapeState.outcome, BattleOutcome.defeat);
  });

  test(
    'headless simulation resolves stage 1 deterministically for a fixed seed',
    () {
      final reportA = BattleEngine.simulate(firstStage, seed: 11);
      final reportB = BattleEngine.simulate(firstStage, seed: 11);

      expect(reportA.outcome, isNot(BattleOutcome.ongoing));
      expect(reportA.turnsUsed, lessThanOrEqualTo(firstStage.turnLimit + 2));
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
}
