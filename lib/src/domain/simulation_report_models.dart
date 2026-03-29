class HeuristicScoreBreakdown {
  const HeuristicScoreBreakdown({
    required this.objectiveContribution,
    required this.killPotentialBonus,
    required this.counterRiskPenalty,
    required this.terrainPreference,
    required this.lowHealthSurvivalBonus,
    required this.bossValueBonus,
    required this.randomnessAdjustment,
  });

  final int objectiveContribution;
  final int killPotentialBonus;
  final int counterRiskPenalty;
  final int terrainPreference;
  final int lowHealthSurvivalBonus;
  final int bossValueBonus;
  final int randomnessAdjustment;

  int get total =>
      objectiveContribution +
      killPotentialBonus +
      counterRiskPenalty +
      terrainPreference +
      lowHealthSurvivalBonus +
      bossValueBonus +
      randomnessAdjustment;
}

class StageSimulationSummary {
  const StageSimulationSummary({
    required this.stageId,
    required this.stageName,
    required this.runs,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.averageTurns,
    required this.targetWinRate,
  });

  final int stageId;
  final String stageName;
  final int runs;
  final int wins;
  final int losses;
  final double winRate;
  final double averageTurns;
  final double targetWinRate;

  Map<String, Object?> toJson() => {
    'stageId': stageId,
    'stageName': stageName,
    'runs': runs,
    'wins': wins,
    'losses': losses,
    'winRate': winRate,
    'averageTurns': averageTurns,
    'targetWinRate': targetWinRate,
  };
}

class SimulationSuiteReport {
  const SimulationSuiteReport({
    required this.generatedAtIso,
    required this.runsPerStage,
    required this.stageSummaries,
  });

  final String generatedAtIso;
  final int runsPerStage;
  final List<StageSimulationSummary> stageSummaries;

  Map<String, Object?> toJson() => {
    'generatedAtIso': generatedAtIso,
    'runsPerStage': runsPerStage,
    'stageSummaries': [
      for (final summary in stageSummaries) summary.toJson(),
    ],
  };

  String toText() {
    final buffer = StringBuffer(
      'Simulation report @ $generatedAtIso (runs $runsPerStage)\n',
    );
    for (final summary in stageSummaries) {
      buffer.writeln(
        'Stage ${summary.stageId} ${summary.stageName} | '
        'wins ${summary.wins}/${summary.runs} | '
        'win ${(summary.winRate * 100).toStringAsFixed(0)}% | '
        'target ${(summary.targetWinRate * 100).toStringAsFixed(0)}% | '
        'avg turns ${summary.averageTurns.toStringAsFixed(1)}',
      );
    }
    return buffer.toString().trimRight();
  }
}
