import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;
  final stages = repository.stages;

  BattleState buildState(int stageId) =>
      BattleEngine.createInitialState(stages.firstWhere((stage) => stage.id == stageId));

  test('stages 1, 4, 6, 8, 10 expose distinct executable objective types', () {
    expect(stages.firstWhere((stage) => stage.id == 1).objectiveType, StageObjectiveType.bossDefeat);
    expect(stages.firstWhere((stage) => stage.id == 4).objectiveType, StageObjectiveType.escort);
    expect(stages.firstWhere((stage) => stage.id == 6).objectiveType, StageObjectiveType.escape);
    expect(stages.firstWhere((stage) => stage.id == 8).objectiveType, StageObjectiveType.holdPosition);
    expect(stages.firstWhere((stage) => stage.id == 10).objectiveType, StageObjectiveType.capturePoints);
  });

  test('boss defeat objective resolves victory when the target boss falls', () {
    final state = buildState(1);
    final boss = state.units.firstWhere((unit) => unit.id == state.stage.objectiveRule.targetUnitIds.single);
    final resolved = state.copyWith(
      units: [
        for (final unit in state.units)
          if (unit.id == boss.id) unit.copyWith(hp: 0) else unit,
      ],
    );

    expect(BattleEngine.evaluateOutcome(resolved), BattleOutcome.victory);
  });

  test('escort objective resolves victory when all required NPCs escape', () {
    final state = buildState(4);
    final resolved = BattleEngine.markUnitEscaped(
      state,
      'xu-zhou-refugee',
    );

    expect(resolved.outcome, BattleOutcome.victory);
    expect(resolved.escapedUnitIds, contains('xu-zhou-refugee'));
  });

  test('npc death loss trigger resolves defeat for escort missions', () {
    final state = buildState(4);
    final defeatedNpc = state.units.firstWhere((unit) => unit.id == 'xu-zhou-refugee');
    final resolved = state.copyWith(
      units: [
        for (final unit in state.units)
          if (unit.id == defeatedNpc.id) unit.copyWith(hp: 0) else unit,
      ],
    );

    expect(BattleEngine.evaluateOutcome(resolved), BattleOutcome.defeat);
  });

  test('escape objective resolves victory after the required number of allies escape', () {
    final state = buildState(6);
    final escaped = ['liu-bei', 'guan-yu', 'zhang-fei', 'zhao-yun'];
    var resolved = state;
    for (final unitId in escaped) {
      resolved = BattleEngine.markUnitEscaped(resolved, unitId);
    }

    expect(resolved.outcome, BattleOutcome.victory);
    expect(resolved.escapedUnitIds.length, 4);
  });

  test('escape failure resolves defeat when the turn limit is exceeded', () {
    final state = buildState(6).copyWith(turn: 10);

    expect(BattleEngine.evaluateOutcome(state), BattleOutcome.defeat);
  });

  test('hold position objective resolves victory after required turns with occupied zone', () {
    final state = buildState(8);
    final zone = state.stage.objectiveRule.targetZoneIds.single;
    final heldState = state.copyWith(
      turn: state.stage.objectiveRule.holdTurns + 1,
      captureStates: {
        ...state.captureStates,
        zone: const CapturePointState(
          pointId: 'changban-bridge',
          controller: Faction.shu,
          heldTurns: 2,
        ),
      },
    );

    expect(state.stage.capturePoints.any((candidate) => candidate.id == zone), isTrue);
    expect(BattleEngine.evaluateOutcome(heldState), BattleOutcome.victory);
  });

  test('capture point objective resolves victory after enough points are secured', () {
    final state = buildState(10);
    final pointIds = state.stage.objectiveRule.targetZoneIds.take(2).toList(growable: false);
    final resolved = state.copyWith(
      captureStates: {
        ...state.captureStates,
        pointIds[0]: CapturePointState(
          pointId: pointIds[0],
          controller: Faction.shu,
          heldTurns: 1,
        ),
        pointIds[1]: CapturePointState(
          pointId: pointIds[1],
          controller: Faction.shu,
          heldTurns: 1,
        ),
      },
    );

    expect(BattleEngine.evaluateOutcome(resolved), BattleOutcome.victory);
    expect(resolved.capturePointControllers[pointIds[0]], Faction.shu);
    expect(resolved.capturePointControllers[pointIds[1]], Faction.shu);
  });

  test('stage definitions expose executable event trigger collections', () {
    for (final stage in stages) {
      expect(stage.eventTriggers, isA<List<StageEventDefinition>>());
    }
  });
}
