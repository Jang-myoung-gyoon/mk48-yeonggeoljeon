import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;
  final firstStage = repository.stages.first;

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
    final strategist = state.units.firstWhere((unit) => unit.id == 'zhuge-liang');
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
      () => BattleEngine.useItem(
        state,
        userId: liuBei.id,
        targetId: 'guan-yu',
      ),
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
    final suddenDeathStage = StageDefinition(
      id: firstStage.id,
      name: firstStage.name,
      motif: firstStage.motif,
      objective: firstStage.objective,
      lossCondition: firstStage.lossCondition,
      gimmick: firstStage.gimmick,
      turnLimit: 1,
      width: firstStage.width,
      height: firstStage.height,
      tiles: firstStage.tiles,
      playerUnits: firstStage.playerUnits,
      enemyUnits: firstStage.enemyUnits,
      targetWinRate: firstStage.targetWinRate,
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
}
