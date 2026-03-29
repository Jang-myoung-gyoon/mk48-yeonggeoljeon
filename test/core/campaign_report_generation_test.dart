import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';

void main() {
  test(
    'campaign simulation report generator writes JSON and markdown artifacts',
    () {
      final iterations = int.parse(
        Platform.environment['CAMPAIGN_REPORT_ITERATIONS'] ?? '6',
      );
      final outputPath =
          Platform.environment['CAMPAIGN_REPORT_OUTPUT'] ??
          '.omx/artifacts/campaign-simulation-report.json';

      final report = BattleEngine.buildSimulationSuite(
        GameDataRepository.instance.stages,
        runsPerStage: iterations,
        generatedAtIso: '2026-03-29T00:00:00Z',
      );

      final jsonFile = File(outputPath);
      jsonFile.parent.createSync(recursive: true);
      jsonFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );

      final markdownFile = File(outputPath.replaceAll('.json', '.txt'));
      markdownFile.writeAsStringSync(report.toText());

      expect(jsonFile.existsSync(), isTrue);
      expect(markdownFile.existsSync(), isTrue);
      expect(jsonFile.readAsStringSync(), contains('runsPerStage'));
      expect(markdownFile.readAsStringSync(), contains('Stage 1'));
    },
  );
}
