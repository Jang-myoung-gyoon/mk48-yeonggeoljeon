import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;
  final stage1 = repository.stages.firstWhere((stage) => stage.id == 1);
  final stage2 = repository.stages.firstWhere((stage) => stage.id == 2);
  final stage10 = repository.stages.firstWhere((stage) => stage.id == 10);

  test('battle-start events trigger immediately and record rewards in the log', () {
    final state = BattleEngine.createInitialState(stage1);

    expect(state.triggeredEvents.map((event) => event.eventId), contains('stage-1-opening-oath'));
    expect(state.log.join('\n'), contains('도원의 맹세'));
    expect(state.rewardLog.join('\n'), contains('전열이 정돈됐다'));
  });

  test('repository defines at least four duel events across the campaign', () {
    final duelEvents = repository.stages
        .expand((stage) => stage.eventTriggers)
        .where((event) => event.duel)
        .toList(growable: false);

    expect(duelEvents.length, greaterThanOrEqualTo(4));
  });

  test('stage 2 guan-yu versus hua-xiong duel defeats the boss and records rewards', () {
    final initial = BattleEngine.createInitialState(stage2);
    final duelReadyUnits = initial.units
        .map(
          (unit) => switch (unit.id) {
            'guan-yu' => unit.copyWith(x: 6, y: 3),
            'hua-xiong' => unit.copyWith(x: 7, y: 3),
            _ => unit,
          },
        )
        .toList(growable: false);

    final resolved = BattleEngine.resolveState(
      initial.copyWith(units: duelReadyUnits),
    );

    expect(
      resolved.triggeredEvents.map((event) => event.eventId),
      contains('duel-guan-yu-vs-hua-xiong'),
    );
    expect(resolved.rewardLog.join('\n'), contains('관우 경험치 +80'));
    expect(resolved.rewardLog.join('\n'), contains('청룡 전리품 획득'));
    expect(
      resolved.units.firstWhere((unit) => unit.id == 'hua-xiong').hp,
      0,
    );
  });

  test('battle-end events trigger after Jingzhou capture victory', () {
    final initial = BattleEngine.createInitialState(stage10);
    final occupied = initial.units
        .map(
          (unit) => switch (unit.id) {
            'liu-bei' => unit.copyWith(x: 7, y: 2),
            'guan-yu' => unit.copyWith(x: 6, y: 5),
            'allied-archer' => unit.copyWith(hp: 0),
            _ => unit,
          },
        )
        .toList(growable: false);

    final resolved = BattleEngine.resolveState(initial.copyWith(units: occupied));

    expect(resolved.outcome, BattleOutcome.victory);
    expect(
      resolved.triggeredEvents.map((event) => event.eventId),
      contains('stage-10-secure-jingzhou'),
    );
    expect(resolved.rewardLog.join('\n'), contains('형주 군량 200석 확보'));
    expect(resolved.rewardLog.join('\n'), contains('형주 진입 루트가 완전히 개방됐다.'));
  });
}
