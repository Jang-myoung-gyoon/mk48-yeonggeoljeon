import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;
  final stage2 = repository.stages[1];

  test('battle-start and battle-end events can be expressed and recorded', () {
    final staged = stage2.copyWith(
      eventTriggers: const [
        StageEventDefinition(
          id: 'opening-banner',
          title: '개전 포고',
          timing: StageEventTiming.battleStart,
          conditions: [
            EventCondition(type: EventConditionType.turnAtLeast, turn: 1),
          ],
          rewards: [],
          logEntry: '개전 포고가 울려 퍼진다.',
        ),
        StageEventDefinition(
          id: 'battle-end-report',
          title: '전투 종결',
          timing: StageEventTiming.battleEnd,
          conditions: [
            EventCondition(
              type: EventConditionType.battleOutcomeIs,
              expectedOutcome: BattleOutcome.victory,
            ),
          ],
          rewards: [
            EventReward(
              type: EventRewardType.branch,
              payload: 'report:opening-secured',
              summary: '전투 보고서가 기록된다.',
            ),
          ],
          logEntry: '승전 보고가 전달된다.',
        ),
      ],
    );

    final startState = BattleEngine.resolveState(
      BattleEngine.createInitialState(staged),
    );
    expect(
      startState.triggeredEvents.map((event) => event.eventId),
      contains('opening-banner'),
    );
    expect(startState.log, contains('개전 포고가 울려 퍼진다.'));

    final victoryState = BattleEngine.resolveState(
      startState.copyWith(
        units: [
          for (final unit in startState.units)
            if (unit.id == 'hua-xiong') unit.copyWith(hp: 0) else unit,
        ],
      ),
    );
    expect(
      victoryState.triggeredEvents.map((event) => event.eventId),
      contains('battle-end-report'),
    );
    expect(victoryState.rewardLog, contains('전투 보고서가 기록된다.'));
  });

  test('stage 2 duel data triggers only when guan yu reaches hua xiong', () {
    expect(stage2.eventTriggers.where((event) => event.duel), isNotEmpty);

    final initialState = BattleEngine.createInitialState(stage2);
    expect(initialState.triggeredEvents.where((event) => event.duel), isEmpty);

    final engagedState = BattleEngine.resolveState(
      initialState.copyWith(
        units: [
          for (final unit in initialState.units)
            if (unit.id == 'guan-yu')
              unit.copyWith(x: 6, y: 3)
            else if (unit.id == 'hua-xiong')
              unit.copyWith(x: 7, y: 3)
            else
              unit,
        ],
      ),
    );

    expect(
      engagedState.triggeredEvents.map((event) => event.eventId),
      contains('duel-guan-yu-vs-hua-xiong'),
    );
    expect(engagedState.log, contains('관우가 화웅에게 일기토를 신청한다.'));
    expect(
      engagedState.units.firstWhere((unit) => unit.id == 'hua-xiong').hp,
      0,
    );
    expect(
      engagedState.rewardLog,
      containsAll(['관우 경험치 +80', '청룡 전리품 획득']),
    );
  });

  test('at least four duel events are data-defined across the campaign', () {
    final duelEvents = repository.stages
        .expand((stage) => stage.eventTriggers)
        .where((event) => event.duel)
        .toList(growable: false);

    expect(duelEvents.length, greaterThanOrEqualTo(4));
  });
}
