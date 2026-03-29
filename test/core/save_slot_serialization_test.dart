import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/campaign_models.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;

  OfficerProgressState progressFor(OfficerProfile officer, int availableFromStageId) {
    return OfficerProgressState(
      officerId: officer.id,
      level: officer.level,
      experience: 12,
      equipmentSlots: officer.defaultEquipment,
      consumableSlots: officer.defaultConsumables,
      skillIds: officer.skillIds,
      availableFromStageId: availableFromStageId,
    );
  }

  test('battle snapshots round-trip current turn, unit state, and event records', () {
    final stage = repository.stages[1];
    final battle = BattleEngine.resolveState(
      BattleEngine.createInitialState(stage).copyWith(
        turn: 4,
        units: [
          for (final unit in BattleEngine.createInitialState(stage).units)
            if (unit.id == 'guan-yu')
              unit.copyWith(x: 6, y: 3, hp: 21, escaped: false, hasMoved: true)
            else
              unit,
        ],
      ),
    );

    final snapshot = BattleSnapshot.fromBattleState(battle);
    final restored = snapshot.toBattleState(repository.stages);

    expect(restored.stage.id, stage.id);
    expect(restored.turn, 4);
    expect(restored.unitById('guan-yu').x, 6);
    expect(restored.unitById('guan-yu').hp, 21);
    expect(restored.triggeredEvents, isNotEmpty);
  });

  test('save slot records preserve formation, growth, inventory, and battle state', () {
    final state = CampaignState(
      selectedStageId: 4,
      unlockedStageIds: const [1, 2, 3, 4, 5],
      clearedStageIds: const [1, 2, 3, 4],
      selectedFormationIds: const ['liu-bei', 'guan-yu', 'zhao-yun'],
      officerProgress: {
        for (final officer in repository.roster.where((officer) => officer.faction == Faction.shu))
          officer.id: progressFor(
            officer,
            switch (officer.id) {
              'zhao-yun' => 4,
              'zhuge-liang' => 7,
              _ => 1,
            },
          ),
      },
      inventory: const ['화웅의 도부', '형주 군량 200석'],
      currentBattle: BattleSnapshot.fromBattleState(
        BattleEngine.createInitialState(repository.stages[3]).copyWith(turn: 5),
      ),
      lastResult: const BattleResultSummary(
        stageId: 4,
        outcome: BattleOutcome.victory,
        experienceAwards: {'guan-yu': 80, 'zhao-yun': 40},
        items: ['화웅의 도부'],
        unlockedStageIds: [5],
        triggeredEventIds: ['duel-guan-yu-vs-hua-xiong'],
      ),
    );
    final record = SaveSlotRecord(
      slotId: SaveSlotId.slot2,
      savedAtIso: '2026-03-29T12:34:56Z',
      label: 'Stage 4 · 서주 구원 · 턴 5',
      state: state,
    );

    final encoded = jsonEncode(record.toJson());
    final decoded = SaveSlotRecord.fromJson(
      jsonDecode(encoded) as Map<String, Object?>,
    );

    expect(decoded.slotId, SaveSlotId.slot2);
    expect(decoded.state.selectedStageId, 4);
    expect(decoded.state.selectedFormationIds, ['liu-bei', 'guan-yu', 'zhao-yun']);
    expect(decoded.state.officerProgress['zhao-yun']!.availableFromStageId, 4);
    expect(decoded.state.officerProgress['zhuge-liang']!.availableFromStageId, 7);
    expect(decoded.state.inventory, containsAll(['화웅의 도부', '형주 군량 200석']));
    expect(decoded.state.currentBattle!.turn, 5);
    expect(decoded.state.lastResult!.items, contains('화웅의 도부'));
  });
}
