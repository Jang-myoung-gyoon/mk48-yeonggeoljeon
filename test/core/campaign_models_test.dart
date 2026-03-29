import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/domain/campaign_models.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  final repository = GameDataRepository.instance;

  OfficerProgressState progressFor(
    OfficerProfile officer, {
    required int availableFromStageId,
  }) {
    return OfficerProgressState(
      officerId: officer.id,
      level: officer.level,
      experience: 0,
      equipmentSlots: officer.defaultEquipment,
      consumableSlots: officer.defaultConsumables,
      skillIds: officer.skillIds,
      availableFromStageId: availableFromStageId,
    );
  }

  test(
    'officer progress state captures level, experience, gear, consumables, and skills',
    () {
      final liuBei = repository.getOfficer('liu-bei');
      final state = progressFor(liuBei, availableFromStageId: 1);

      expect(state.officerId, 'liu-bei');
      expect(state.level, liuBei.level);
      expect(state.experience, 0);
      expect(state.equipmentSlots, liuBei.defaultEquipment);
      expect(state.consumableSlots, liuBei.defaultConsumables);
      expect(state.skillIds, liuBei.skillIds);
    },
  );

  test(
    'campaign state preserves zhao yun and zhuge liang availability thresholds',
    () {
      final state = CampaignState(
        selectedStageId: 4,
        unlockedStageIds: const [1, 2, 3, 4],
        clearedStageIds: const [1, 2, 3],
        selectedFormationIds: const ['liu-bei', 'guan-yu', 'zhang-fei'],
        officerProgress: {
          for (final officer
              in repository.roster.where((officer) => officer.faction == Faction.shu))
            officer.id: progressFor(
              officer,
              availableFromStageId: switch (officer.id) {
                'zhao-yun' => 4,
                'zhuge-liang' => 7,
                _ => 1,
              },
            ),
        },
        inventory: const [],
      );

      expect(state.officerProgress['zhao-yun']?.availableFromStageId, 4);
      expect(state.officerProgress['zhuge-liang']?.availableFromStageId, 7);
    },
  );
}
