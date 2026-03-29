import 'battle_engine.dart';
import 'models.dart';

enum SaveSlotId { slot1, slot2, slot3 }

class OfficerProgressState {
  const OfficerProgressState({
    required this.officerId,
    required this.level,
    required this.experience,
    required this.equipmentSlots,
    required this.consumableSlots,
    required this.skillIds,
    required this.availableFromStageId,
  });

  final String officerId;
  final int level;
  final int experience;
  final List<String> equipmentSlots;
  final List<String> consumableSlots;
  final List<String> skillIds;
  final int availableFromStageId;

  OfficerProgressState copyWith({
    int? level,
    int? experience,
    List<String>? equipmentSlots,
    List<String>? consumableSlots,
    List<String>? skillIds,
    int? availableFromStageId,
  }) {
    return OfficerProgressState(
      officerId: officerId,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      equipmentSlots: equipmentSlots ?? this.equipmentSlots,
      consumableSlots: consumableSlots ?? this.consumableSlots,
      skillIds: skillIds ?? this.skillIds,
      availableFromStageId: availableFromStageId ?? this.availableFromStageId,
    );
  }

  Map<String, Object?> toJson() => {
    'officerId': officerId,
    'level': level,
    'experience': experience,
    'equipmentSlots': equipmentSlots,
    'consumableSlots': consumableSlots,
    'skillIds': skillIds,
    'availableFromStageId': availableFromStageId,
  };

  static OfficerProgressState fromJson(Map<String, Object?> json) {
    return OfficerProgressState(
      officerId: json['officerId']! as String,
      level: json['level']! as int,
      experience: json['experience']! as int,
      equipmentSlots: List<String>.from(json['equipmentSlots']! as List),
      consumableSlots: List<String>.from(json['consumableSlots']! as List),
      skillIds: List<String>.from(json['skillIds']! as List),
      availableFromStageId: json['availableFromStageId']! as int,
    );
  }
}

class BattleUnitSnapshot {
  const BattleUnitSnapshot({
    required this.id,
    required this.x,
    required this.y,
    required this.hp,
    required this.escaped,
    required this.hasMoved,
    required this.hasActed,
  });

  final String id;
  final int x;
  final int y;
  final int hp;
  final bool escaped;
  final bool hasMoved;
  final bool hasActed;

  factory BattleUnitSnapshot.fromUnit(BattleUnit unit) {
    return BattleUnitSnapshot(
      id: unit.id,
      x: unit.x,
      y: unit.y,
      hp: unit.hp,
      escaped: unit.escaped,
      hasMoved: unit.hasMoved,
      hasActed: unit.hasActed,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    'hp': hp,
    'escaped': escaped,
    'hasMoved': hasMoved,
    'hasActed': hasActed,
  };

  static BattleUnitSnapshot fromJson(Map<String, Object?> json) {
    return BattleUnitSnapshot(
      id: json['id']! as String,
      x: json['x']! as int,
      y: json['y']! as int,
      hp: json['hp']! as int,
      escaped: json['escaped']! as bool,
      hasMoved: json['hasMoved']! as bool,
      hasActed: json['hasActed']! as bool,
    );
  }
}

class BattleSnapshot {
  const BattleSnapshot({
    required this.stageId,
    required this.turn,
    required this.phase,
    required this.outcome,
    required this.units,
    required this.captureStates,
    required this.escapedUnitIds,
    required this.triggeredEvents,
    required this.rewardLog,
  });

  final int stageId;
  final int turn;
  final BattlePhase phase;
  final BattleOutcome outcome;
  final List<BattleUnitSnapshot> units;
  final Map<String, CapturePointState> captureStates;
  final List<String> escapedUnitIds;
  final List<BattleEventRecord> triggeredEvents;
  final List<String> rewardLog;

  factory BattleSnapshot.fromBattleState(BattleState state) {
    return BattleSnapshot(
      stageId: state.stage.id,
      turn: state.turn,
      phase: state.phase,
      outcome: state.outcome,
      units: state.units.map(BattleUnitSnapshot.fromUnit).toList(growable: false),
      captureStates: Map<String, CapturePointState>.from(state.captureStates),
      escapedUnitIds: List<String>.from(state.escapedUnitIds),
      triggeredEvents: List<BattleEventRecord>.from(state.triggeredEvents),
      rewardLog: List<String>.from(state.rewardLog),
    );
  }

  BattleState toBattleState(List<StageDefinition> stages) {
    final stage = stages.firstWhere((candidate) => candidate.id == stageId);
    final initial = BattleEngine.createInitialState(stage);
    final unitsById = {for (final unit in initial.units) unit.id: unit};
    final restoredUnits = [
      for (final snapshot in units)
        unitsById[snapshot.id]!.copyWith(
          x: snapshot.x,
          y: snapshot.y,
          hp: snapshot.hp,
          escaped: snapshot.escaped,
          turnState: UnitTurnState(
            hasMoved: snapshot.hasMoved,
            hasActed: snapshot.hasActed,
          ),
        ),
    ];
    return initial.copyWith(
      turn: turn,
      phase: phase,
      outcome: outcome,
      units: restoredUnits,
      captureStates: captureStates,
      escapedUnitIds: escapedUnitIds,
      triggeredEvents: triggeredEvents,
      rewardLog: rewardLog,
    );
  }

  Map<String, Object?> toJson() => {
    'stageId': stageId,
    'turn': turn,
    'phase': phase.name,
    'outcome': outcome.name,
    'units': units.map((unit) => unit.toJson()).toList(growable: false),
    'captureStates': {
      for (final entry in captureStates.entries)
        entry.key: {
          'pointId': entry.value.pointId,
          'controller': entry.value.controller?.name,
          'heldTurns': entry.value.heldTurns,
        },
    },
    'escapedUnitIds': escapedUnitIds,
    'triggeredEvents': [
      for (final event in triggeredEvents)
        {
          'eventId': event.eventId,
          'title': event.title,
          'logEntry': event.logEntry,
          'triggeredTurn': event.triggeredTurn,
          'duel': event.duel,
        },
    ],
    'rewardLog': rewardLog,
  };

  static BattleSnapshot fromJson(Map<String, Object?> json) {
    final captureStateJson = json['captureStates']! as Map<String, Object?>;
    return BattleSnapshot(
      stageId: json['stageId']! as int,
      turn: json['turn']! as int,
      phase: BattlePhase.values.byName(json['phase']! as String),
      outcome: BattleOutcome.values.byName(json['outcome']! as String),
      units: (json['units']! as List)
          .cast<Map<String, Object?>>()
          .map(BattleUnitSnapshot.fromJson)
          .toList(growable: false),
      captureStates: {
        for (final entry in captureStateJson.entries)
          entry.key: CapturePointState(
            pointId: (entry.value as Map<String, Object?>)['pointId']! as String,
            controller: (entry.value as Map<String, Object?>)['controller'] == null
                ? null
                : Faction.values.byName(
                    (entry.value as Map<String, Object?>)['controller']! as String,
                  ),
            heldTurns: (entry.value as Map<String, Object?>)['heldTurns']! as int,
          ),
      },
      escapedUnitIds: List<String>.from(json['escapedUnitIds']! as List),
      triggeredEvents: (json['triggeredEvents']! as List)
          .cast<Map<String, Object?>>()
          .map(
            (event) => BattleEventRecord(
              eventId: event['eventId']! as String,
              title: event['title']! as String,
              logEntry: event['logEntry']! as String,
              triggeredTurn: event['triggeredTurn']! as int,
              duel: event['duel']! as bool,
            ),
          )
          .toList(growable: false),
      rewardLog: List<String>.from(json['rewardLog']! as List),
    );
  }
}

class BattleResultSummary {
  const BattleResultSummary({
    required this.stageId,
    required this.outcome,
    required this.experienceAwards,
    required this.items,
    required this.unlockedStageIds,
    required this.triggeredEventIds,
  });

  final int stageId;
  final BattleOutcome outcome;
  final Map<String, int> experienceAwards;
  final List<String> items;
  final List<int> unlockedStageIds;
  final List<String> triggeredEventIds;

  Map<String, Object?> toJson() => {
    'stageId': stageId,
    'outcome': outcome.name,
    'experienceAwards': experienceAwards,
    'items': items,
    'unlockedStageIds': unlockedStageIds,
    'triggeredEventIds': triggeredEventIds,
  };

  static BattleResultSummary fromJson(Map<String, Object?> json) {
    return BattleResultSummary(
      stageId: json['stageId']! as int,
      outcome: BattleOutcome.values.byName(json['outcome']! as String),
      experienceAwards: Map<String, int>.from(
        (json['experienceAwards']! as Map).map(
          (key, value) => MapEntry(key as String, value as int),
        ),
      ),
      items: List<String>.from(json['items']! as List),
      unlockedStageIds: List<int>.from(json['unlockedStageIds']! as List),
      triggeredEventIds: List<String>.from(json['triggeredEventIds']! as List),
    );
  }
}

class CampaignState {
  const CampaignState({
    required this.selectedStageId,
    required this.unlockedStageIds,
    required this.clearedStageIds,
    required this.selectedFormationIds,
    required this.officerProgress,
    required this.inventory,
    this.currentBattle,
    this.lastResult,
  });

  final int selectedStageId;
  final List<int> unlockedStageIds;
  final List<int> clearedStageIds;
  final List<String> selectedFormationIds;
  final Map<String, OfficerProgressState> officerProgress;
  final List<String> inventory;
  final BattleSnapshot? currentBattle;
  final BattleResultSummary? lastResult;

  CampaignState copyWith({
    int? selectedStageId,
    List<int>? unlockedStageIds,
    List<int>? clearedStageIds,
    List<String>? selectedFormationIds,
    Map<String, OfficerProgressState>? officerProgress,
    List<String>? inventory,
    BattleSnapshot? currentBattle,
    bool clearCurrentBattle = false,
    BattleResultSummary? lastResult,
    bool clearLastResult = false,
  }) {
    return CampaignState(
      selectedStageId: selectedStageId ?? this.selectedStageId,
      unlockedStageIds: unlockedStageIds ?? this.unlockedStageIds,
      clearedStageIds: clearedStageIds ?? this.clearedStageIds,
      selectedFormationIds: selectedFormationIds ?? this.selectedFormationIds,
      officerProgress: officerProgress ?? this.officerProgress,
      inventory: inventory ?? this.inventory,
      currentBattle: clearCurrentBattle ? null : currentBattle ?? this.currentBattle,
      lastResult: clearLastResult ? null : lastResult ?? this.lastResult,
    );
  }

  Map<String, Object?> toJson() => {
    'selectedStageId': selectedStageId,
    'unlockedStageIds': unlockedStageIds,
    'clearedStageIds': clearedStageIds,
    'selectedFormationIds': selectedFormationIds,
    'officerProgress': {
      for (final entry in officerProgress.entries) entry.key: entry.value.toJson(),
    },
    'inventory': inventory,
    'currentBattle': currentBattle?.toJson(),
    'lastResult': lastResult?.toJson(),
  };

  static CampaignState fromJson(Map<String, Object?> json) {
    final officerProgressJson = json['officerProgress']! as Map<String, Object?>;
    return CampaignState(
      selectedStageId: json['selectedStageId']! as int,
      unlockedStageIds: List<int>.from(json['unlockedStageIds']! as List),
      clearedStageIds: List<int>.from(json['clearedStageIds']! as List),
      selectedFormationIds: List<String>.from(json['selectedFormationIds']! as List),
      officerProgress: {
        for (final entry in officerProgressJson.entries)
          entry.key: OfficerProgressState.fromJson(entry.value! as Map<String, Object?>),
      },
      inventory: List<String>.from(json['inventory']! as List),
      currentBattle: json['currentBattle'] == null
          ? null
          : BattleSnapshot.fromJson(json['currentBattle']! as Map<String, Object?>),
      lastResult: json['lastResult'] == null
          ? null
          : BattleResultSummary.fromJson(json['lastResult']! as Map<String, Object?>),
    );
  }
}

class SaveSlotRecord {
  const SaveSlotRecord({
    required this.slotId,
    required this.savedAtIso,
    required this.label,
    required this.state,
  });

  final SaveSlotId slotId;
  final String savedAtIso;
  final String label;
  final CampaignState state;

  Map<String, Object?> toJson() => {
    'slotId': slotId.name,
    'savedAtIso': savedAtIso,
    'label': label,
    'state': state.toJson(),
  };

  static SaveSlotRecord fromJson(Map<String, Object?> json) {
    return SaveSlotRecord(
      slotId: SaveSlotId.values.byName(json['slotId']! as String),
      savedAtIso: json['savedAtIso']! as String,
      label: json['label']! as String,
      state: CampaignState.fromJson(json['state']! as Map<String, Object?>),
    );
  }
}
