import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/data/game_session_controller.dart';
import 'package:ralphthon/src/data/save_slot_store.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/campaign_models.dart';

class _MemorySaveSlotStore implements SaveSlotStore {
  final Map<SaveSlotId, SaveSlotRecord> _records = {};

  @override
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots() async => Map.of(_records);

  @override
  Future<void> writeSlot(SaveSlotRecord record) async {
    _records[record.slotId] = record;
  }
}

void main() {
  final repository = GameDataRepository.instance;

  test(
    'applying a victory result unlocks the next stage and newly joined officers',
    () {
      final session = GameSessionController(
        repository,
        saveSlotStore: _MemorySaveSlotStore(),
      );
      session.selectStage(3);
      final battle = session.startSelectedStage(notify: false);
      final victory = BattleEngine.resolveState(
        battle.copyWith(
          units: [
            for (final unit in battle.units)
              if (unit.id == battle.stage.boss.id)
                unit.copyWith(hp: 0)
              else
                unit,
          ],
        ),
      );

      session.updateCurrentBattle(victory);
      expect(session.lastResult?.unlockedStageIds, [4]);

      session.applyLastResult();

      expect(session.campaignState.unlockedStageIds, contains(4));
      expect(
        session.availableOfficers.map((officer) => officer.id),
        contains('zhao-yun'),
      );
      expect(session.currentBattle, isNull);
      expect(session.lastResult, isNull);
    },
  );

  test(
    'saveToSlot and loadFromSlot round-trip the selected stage and formation',
    () async {
      final store = _MemorySaveSlotStore();
      final session = GameSessionController(repository, saveSlotStore: store);

      session.selectStage(4);
      session.toggleFormation('guan-yu');
      await session.saveToSlot(SaveSlotId.slot1);

      session.selectStage(1);
      await session.loadFromSlot(SaveSlotId.slot1);

      expect(session.campaignState.selectedStageId, 4);
      expect(
        session.campaignState.selectedFormationIds,
        isNot(contains('guan-yu')),
      );
      expect(session.slots[SaveSlotId.slot1]?.label, contains('Stage 4'));
    },
  );
}
