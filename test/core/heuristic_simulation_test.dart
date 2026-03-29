import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';

void main() {
  final repository = GameDataRepository.instance;
  final stage1 = repository.stages.first;

  test('heuristic breakdown exposes the required decision factors deterministically', () {
    final state = BattleEngine.createInitialState(stage1);
    final actor = state.units.firstWhere((unit) => unit.id == 'guan-yu');
    final target = state.units.firstWhere((unit) => unit.id == 'hua-xiong');

    final scoreA = BattleEngine.scoreHeuristicTarget(state, actor, target, seed: 17);
    final scoreB = BattleEngine.scoreHeuristicTarget(state, actor, target, seed: 17);

    expect(scoreA.objectiveContribution, isNotNull);
    expect(scoreA.killPotentialBonus, isNotNull);
    expect(scoreA.counterRiskPenalty, isNotNull);
    expect(scoreA.terrainPreference, isNotNull);
    expect(scoreA.lowHealthSurvivalBonus, isNotNull);
    expect(scoreA.bossValueBonus, isNotNull);
    expect(scoreA.randomnessAdjustment, isNotNull);
    expect(scoreA.total, scoreB.total);
  });

  test('stage simulation summaries are reproducible for a fixed seed', () {
    final summaryA = BattleEngine.simulateStageSeries(stage1, runs: 5, seed: 11);
    final summaryB = BattleEngine.simulateStageSeries(stage1, runs: 5, seed: 11);

    expect(summaryA.stageId, 1);
    expect(summaryA.winRate, summaryB.winRate);
    expect(summaryA.averageTurns, summaryB.averageTurns);
    expect(summaryA.wins + summaryA.losses, 5);
  });

  test('simulation suite report preserves PRD target win rates and serializes cleanly', () {
    final report = BattleEngine.buildSimulationSuite(
      repository.stages,
      runsPerStage: 3,
      seed: 23,
      generatedAtIso: '2026-03-29T00:00:00Z',
    );

    expect(report.stageSummaries.first.targetWinRate, 0.9);
    expect(report.stageSummaries[3].targetWinRate, 0.3);
    expect(report.toJson()['runsPerStage'], 3);
    expect(report.toText(), contains('Stage 1'));
    expect(report.toText(), contains('target 90%'));
    expect(report.toText(), contains('target 30%'));
  });
}
