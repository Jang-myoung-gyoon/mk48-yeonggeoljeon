import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/battle_engine.dart';
import '../domain/campaign_models.dart';
import '../domain/models.dart';
import 'game_data.dart';
import 'save_slot_store.dart';
import 'save_slot_store_factory.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController(
    this.repository, {
    SaveSlotStore? saveSlotStore,
  }) : _saveSlotStore = saveSlotStore ?? createPlatformSaveSlotStore(),
       _campaignState = _initialCampaignState(repository) {
    unawaited(hydrateSlots());
  }

  final GameDataRepository repository;
  final SaveSlotStore _saveSlotStore;
  CampaignState _campaignState;
  Map<SaveSlotId, SaveSlotRecord> _slots = {};

  CampaignState get campaignState => _campaignState;
  Map<SaveSlotId, SaveSlotRecord> get slots => _slots;
  StageDefinition get selectedStage =>
      repository.stages.firstWhere((stage) => stage.id == _campaignState.selectedStageId);

  List<OfficerProfile> get availableOfficers => repository.heroes
      .where(
        (officer) =>
            (_campaignState.officerProgress[officer.id]?.availableFromStageId ?? 99) <=
            _highestUnlockedStageId,
      )
      .toList(growable: false);

  BattleState? get currentBattle => _campaignState.currentBattle?.toBattleState(repository.stages);

  BattleResultSummary? get lastResult => _campaignState.lastResult;

  int get _highestUnlockedStageId => _campaignState.unlockedStageIds.isEmpty
      ? 1
      : _campaignState.unlockedStageIds.reduce((a, b) => a > b ? a : b);

  Future<void> hydrateSlots() async {
    _slots = await _saveSlotStore.loadSlots();
    notifyListeners();
  }

  void selectStage(int stageId) {
    _campaignState = _campaignState.copyWith(selectedStageId: stageId);
    final allowedIds = availableOfficers.map((officer) => officer.id).toSet();
    final nextFormation = _campaignState.selectedFormationIds
        .where(allowedIds.contains)
        .toList(growable: false);
    if (nextFormation.isEmpty) {
      _campaignState = _campaignState.copyWith(
        selectedFormationIds: _defaultFormationForStage(stageId),
      );
    } else {
      _campaignState = _campaignState.copyWith(selectedFormationIds: nextFormation);
    }
    notifyListeners();
  }

  void toggleFormation(String officerId) {
    final selected = [..._campaignState.selectedFormationIds];
    if (selected.contains(officerId)) {
      if (selected.length <= 1) {
        return;
      }
      selected.remove(officerId);
    } else {
      if (selected.length >= 5) {
        return;
      }
      selected.add(officerId);
    }
    _campaignState = _campaignState.copyWith(selectedFormationIds: selected);
    notifyListeners();
  }

  BattleState startSelectedStage({bool notify = true}) {
    final npcPlacements = selectedStage.playerUnits.where((unit) => unit.profile.isNpc).toList(growable: false);
    final slotPositions = selectedStage.playerUnits
        .where((unit) => !unit.profile.isNpc)
        .map((unit) => unit.position)
        .toList(growable: false);
    final chosenProfiles = _campaignState.selectedFormationIds
        .map(repository.getOfficer)
        .toList(growable: false);
    final chosenPlacements = [
      for (var i = 0; i < chosenProfiles.length && i < slotPositions.length; i++)
        UnitPlacement(
          profile: chosenProfiles[i],
          x: slotPositions[i].x,
          y: slotPositions[i].y,
        ),
    ];
    final stage = selectedStage.copyWith(playerUnits: [...chosenPlacements, ...npcPlacements]);
    final battle = BattleEngine.createInitialState(stage);
    _campaignState = _campaignState.copyWith(
      currentBattle: BattleSnapshot.fromBattleState(battle),
      clearLastResult: true,
    );
    if (notify) {
      notifyListeners();
    }
    return battle;
  }

  void updateCurrentBattle(BattleState battle) {
    _campaignState = _campaignState.copyWith(
      currentBattle: BattleSnapshot.fromBattleState(battle),
    );
    if (battle.outcome != BattleOutcome.ongoing) {
      _campaignState = _campaignState.copyWith(lastResult: _buildResultSummary(battle));
    }
    notifyListeners();
  }

  BattleResultSummary _buildResultSummary(BattleState battle) {
    final experienceAwards = <String, int>{};
    final items = <String>[];

    for (final unitId in _campaignState.selectedFormationIds) {
      experienceAwards[unitId] = battle.outcome == BattleOutcome.victory ? 20 : 8;
    }

    for (final record in battle.triggeredEvents) {
      final definition = battle.stage.eventTriggers.firstWhere(
        (event) => event.id == record.eventId,
      );
      for (final reward in definition.rewards) {
        switch (reward.type) {
          case EventRewardType.experience:
            if (reward.targetUnitId != null) {
              experienceAwards.update(
                reward.targetUnitId!,
                (current) => current + (reward.amount ?? 0),
                ifAbsent: () => reward.amount ?? 0,
              );
            }
          case EventRewardType.item:
            if (reward.payload != null) {
              items.add(reward.payload!);
            }
          case EventRewardType.morale:
          case EventRewardType.branch:
          case EventRewardType.defeatUnit:
            break;
        }
      }
    }

    final unlockedStageIds = battle.outcome == BattleOutcome.victory &&
            battle.stage.id < repository.stages.length
        ? [battle.stage.id + 1]
        : const <int>[];

    return BattleResultSummary(
      stageId: battle.stage.id,
      outcome: battle.outcome,
      experienceAwards: experienceAwards,
      items: items,
      unlockedStageIds: unlockedStageIds,
      triggeredEventIds: battle.triggeredEvents.map((event) => event.eventId).toList(growable: false),
    );
  }

  void applyLastResult() {
    final result = _campaignState.lastResult;
    if (result == null) {
      return;
    }
    final nextProgress = Map<String, OfficerProgressState>.from(_campaignState.officerProgress);
    for (final entry in result.experienceAwards.entries) {
      final current = nextProgress[entry.key];
      if (current == null) {
        continue;
      }
      final totalExp = current.experience + entry.value;
      nextProgress[entry.key] = current.copyWith(
        experience: totalExp,
        level: current.level + (totalExp ~/ 100),
      );
    }
    final nextUnlocked = {..._campaignState.unlockedStageIds, ...result.unlockedStageIds}.toList()..sort();
    final nextCleared = {..._campaignState.clearedStageIds, if (result.outcome == BattleOutcome.victory) result.stageId}.toList()..sort();
    _campaignState = _campaignState.copyWith(
      unlockedStageIds: nextUnlocked,
      clearedStageIds: nextCleared,
      officerProgress: nextProgress,
      inventory: [..._campaignState.inventory, ...result.items],
      clearCurrentBattle: true,
      clearLastResult: true,
    );
    notifyListeners();
  }

  Future<void> saveToSlot(SaveSlotId slotId) async {
    final label = 'Stage ${_campaignState.selectedStageId} · ${selectedStage.name}';
    final record = SaveSlotRecord(
      slotId: slotId,
      savedAtIso: DateTime.now().toUtc().toIso8601String(),
      label: label,
      state: _campaignState,
    );
    await _saveSlotStore.writeSlot(record);
    _slots = {..._slots, slotId: record};
    notifyListeners();
  }

  Future<void> loadFromSlot(SaveSlotId slotId) async {
    final record = _slots[slotId];
    if (record == null) {
      return;
    }
    _campaignState = record.state;
    notifyListeners();
  }

  static CampaignState _initialCampaignState(GameDataRepository repository) {
    final officerProgress = {
      for (final officer in repository.roster.where((officer) => officer.faction == Faction.shu))
        officer.id: OfficerProgressState(
          officerId: officer.id,
          level: officer.level,
          experience: 0,
          equipmentSlots: List<String>.from(officer.defaultEquipment),
          consumableSlots: List<String>.from(officer.defaultConsumables),
          skillIds: List<String>.from(officer.skillIds),
          availableFromStageId: switch (officer.id) {
            'zhao-yun' => 4,
            'zhuge-liang' => 7,
            _ => 1,
          },
        ),
    };
    return CampaignState(
      selectedStageId: 1,
      unlockedStageIds: const [1],
      clearedStageIds: const [],
      selectedFormationIds: const ['liu-bei', 'guan-yu', 'zhang-fei'],
      officerProgress: officerProgress,
      inventory: const [],
    );
  }

  List<String> _defaultFormationForStage(int stageId) {
    final pool = availableOfficers.map((officer) => officer.id).toList(growable: false);
    return pool.take(stageId >= 7 ? 5 : stageId >= 4 ? 4 : 3).toList(growable: false);
  }
}
