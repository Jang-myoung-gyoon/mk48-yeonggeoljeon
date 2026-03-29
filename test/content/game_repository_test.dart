import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/app/app.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;

  test('campaign data exposes the 10-stage story arc and five Shu heroes', () {
    expect(repository.stages, hasLength(10));
    expect(
      repository.roster
          .where((officer) => officer.faction == Faction.shu && !officer.isNpc)
          .map((hero) => hero.name),
      ['유비', '관우', '장비', '조운', '제갈량'],
    );
  });

  test('required route list stays aligned with the PRD navigation scope', () {
    expect(NanseHeroesApp.routeSpecs, hasLength(14));
    expect(NanseHeroesApp.routeSpecs.first.route, AppRoute.title);
    expect(NanseHeroesApp.routeSpecs.last.route, AppRoute.gameOver);
  });

  test('stage balance buckets follow the PRD targets', () {
    final early = repository.stages.take(3).map((stage) => stage.targetWinRate);
    final late = repository.stages.skip(3).map((stage) => stage.targetWinRate);

    expect(early, everyElement(0.9));
    expect(late, everyElement(0.3));
  });

  test('stages preserve boss mapping and tactical gimmicks from the PRD', () {
    expect(repository.stages[1].boss.name, '화웅');
    expect(repository.stages[2].boss.name, '여포');
    expect(repository.stages[6].gimmick, contains('화계'));
    expect(repository.stages[7].objectiveType, StageObjectiveType.holdPosition);
  });

  test('stage metadata preserves PRD turn limits and finale pressure', () {
    expect(repository.stages.first.turnLimit, 8);
    expect(repository.stages[1].turnLimit, 12);
    expect(repository.stages.last.turnLimit, 12);
    expect(repository.stages.last.objective, contains('점령'));
    expect(repository.stages.last.gimmick, contains('증원'));
  });

  test('stages 1, 4, 6, 8, 10 expose distinct executable objective types', () {
    expect(repository.stages[0].objectiveType, StageObjectiveType.bossDefeat);
    expect(repository.stages[3].objectiveType, StageObjectiveType.escort);
    expect(repository.stages[5].objectiveType, StageObjectiveType.escape);
    expect(repository.stages[7].objectiveType, StageObjectiveType.holdPosition);
    expect(
      repository.stages[9].objectiveType,
      StageObjectiveType.capturePoints,
    );
  });

  test(
    'loss and zone metadata is available for escort, escape, hold, and capture stages',
    () {
      expect(
        repository.stages[3].lossTriggers.map((trigger) => trigger.type),
        contains(LossTriggerType.npcDead),
      );
      expect(repository.stages[3].escapeZones, isNotEmpty);
      expect(
        repository.stages[5].lossTriggers.map((trigger) => trigger.type),
        contains(LossTriggerType.escapeFailure),
      );
      expect(repository.stages[7].capturePoints, hasLength(1));
      expect(repository.stages[9].capturePoints, hasLength(2));
    },
  );
}
