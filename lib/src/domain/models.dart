class GridPoint {
  const GridPoint(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}

class RequiredScreen {
  const RequiredScreen({
    required this.code,
    required this.title,
    required this.purpose,
  });

  final String code;
  final String title;
  final String purpose;
}

enum Faction { shu, enemy, neutral }

enum UnitClass { lord, guardian, lancer, cavalry, strategist, raider, archer }

enum TerrainType { plain, forest, gate, road, river, village, wall }

enum BattlePhase { player, enemy }

enum BattleOutcome { ongoing, victory, defeat }

enum StageObjectiveType {
  bossDefeat,
  escape,
  escort,
  holdPosition,
  capturePoints,
}

enum LossTriggerType { lordDead, npcDead, turnLimit, escapeFailure }

enum StageEventTiming { battleStart, turnStart, turnEnd, battleEnd, duel }

enum ObjectiveZoneType { capture, escape }

enum EventConditionType {
  turnAtLeast,
  unitWithinRange,
  unitAtPoint,
  unitEscaped,
  battleOutcomeIs,
  capturePointControlled,
}

enum EventRewardType { experience, morale, item, branch, defeatUnit }

extension TerrainTypeUi on TerrainType {
  String get label => switch (this) {
    TerrainType.plain => '평지',
    TerrainType.forest => '숲',
    TerrainType.gate => '관문',
    TerrainType.road => '도로',
    TerrainType.river => '강',
    TerrainType.village => '마을',
    TerrainType.wall => '성벽',
  };

  int get defenseBonus => switch (this) {
    TerrainType.forest => 2,
    TerrainType.gate => 3,
    TerrainType.village => 1,
    TerrainType.wall => 4,
    _ => 0,
  };

  bool get passable => this != TerrainType.river && this != TerrainType.wall;
}

extension UnitClassUi on UnitClass {
  String get label => switch (this) {
    UnitClass.lord => '군주',
    UnitClass.guardian => '중장 보병',
    UnitClass.lancer => '창병',
    UnitClass.cavalry => '기병',
    UnitClass.strategist => '군사',
    UnitClass.raider => '돌격장',
    UnitClass.archer => '궁병',
  };
}

extension FactionUi on Faction {
  String get label => switch (this) {
    Faction.shu => '유비군',
    Faction.enemy => '적군',
    Faction.neutral => '중립',
  };
}

extension IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}

class OfficerProfile {
  const OfficerProfile({
    required this.id,
    required this.name,
    required this.unitClass,
    required this.faction,
    required this.title,
    required this.signature,
    required this.visual,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.mobility,
    required this.range,
    required this.level,
    this.isBoss = false,
    this.isNpc = false,
    this.spriteId,
    this.defaultEquipment = const <String>[],
    this.defaultConsumables = const <String>[],
    this.skillIds = const <String>[],
  });

  final String id;
  final String name;
  final UnitClass unitClass;
  final Faction faction;
  final String title;
  final String signature;
  final String visual;
  final int maxHp;
  final int attack;
  final int defense;
  final int mobility;
  final int range;
  final int level;
  final bool isBoss;
  final bool isNpc;
  final String? spriteId;
  final List<String> defaultEquipment;
  final List<String> defaultConsumables;
  final List<String> skillIds;
}

class TerrainTile {
  const TerrainTile({required this.x, required this.y, required this.type});

  final int x;
  final int y;
  final TerrainType type;

  GridPoint get point => GridPoint(x, y);
}

class UnitPlacement {
  const UnitPlacement({
    required this.profile,
    required this.x,
    required this.y,
  });

  final OfficerProfile profile;
  final int x;
  final int y;

  GridPoint get position => GridPoint(x, y);
}

class StageObjectiveRule {
  const StageObjectiveRule({
    required this.type,
    required this.description,
    this.trackedUnitIds = const <String>[],
    this.targetPointIds = const <String>[],
    this.requiredCount = 1,
    this.holdTurns = 1,
    this.turnDeadline,
    this.controlFaction = Faction.shu,
  });

  final StageObjectiveType type;
  final String description;
  final List<String> trackedUnitIds;
  final List<String> targetPointIds;
  final int requiredCount;
  final int holdTurns;
  final int? turnDeadline;
  final Faction controlFaction;

  List<String> get targetUnitIds => trackedUnitIds;
  List<String> get targetPointIdsAlias => targetPointIds;
  List<String> get targetZoneIds => targetPointIds;
  List<String> get zoneIds => targetPointIds;
  int? get requiredTurn => turnDeadline;
  int? get requiredTurns => turnDeadline;
  Faction get requiredFaction => controlFaction;
}

class StageLossRule {
  const StageLossRule({
    required this.type,
    required this.description,
    this.trackedUnitIds = const <String>[],
    this.turnDeadline,
    this.requiredCount = 1,
  });

  final LossTriggerType type;
  final String description;
  final List<String> trackedUnitIds;
  final int? turnDeadline;
  final int requiredCount;

  List<String> get unitIds => trackedUnitIds;
  List<String> get targetUnitIds => trackedUnitIds;
  List<String> get zoneIds => const <String>[];
  int? get turnLimit => turnDeadline;
}

class CapturePointDefinition {
  const CapturePointDefinition({
    required this.id,
    required this.label,
    required this.position,
  });

  final String id;
  final String label;
  final GridPoint position;
}

class EscapeZoneDefinition {
  const EscapeZoneDefinition({
    required this.id,
    required this.label,
    required this.tiles,
    this.eligibleUnitIds = const <String>[],
  });

  final String id;
  final String label;
  final List<GridPoint> tiles;
  final List<String> eligibleUnitIds;

  bool matches(BattleUnit unit) {
    final idAllowed =
        eligibleUnitIds.isEmpty || eligibleUnitIds.contains(unit.id);
    return idAllowed && tiles.contains(unit.position);
  }
}

class ObjectiveZoneDefinition {
  const ObjectiveZoneDefinition({
    required this.id,
    required this.label,
    required this.type,
    required this.tiles,
  });

  final String id;
  final String label;
  final ObjectiveZoneType type;
  final List<GridPoint> tiles;

  bool contains(GridPoint point) => tiles.contains(point);
}

class EventCondition {
  const EventCondition({
    required this.type,
    this.trackedUnitIds = const <String>[],
    this.targetPointIds = const <String>[],
    this.turn,
    this.range,
    this.expectedOutcome,
    this.controllingFaction,
  });

  final EventConditionType type;
  final List<String> trackedUnitIds;
  final List<String> targetPointIds;
  final int? turn;
  final int? range;
  final BattleOutcome? expectedOutcome;
  final Faction? controllingFaction;
}

class EventReward {
  const EventReward({
    required this.type,
    this.targetUnitId,
    this.amount,
    this.payload,
    this.summary,
  });

  final EventRewardType type;
  final String? targetUnitId;
  final int? amount;
  final String? payload;
  final String? summary;
}

class StageEventDefinition {
  const StageEventDefinition({
    required this.id,
    required this.title,
    required this.timing,
    required this.conditions,
    required this.rewards,
    required this.logEntry,
    this.duel = false,
    this.once = true,
  });

  final String id;
  final String title;
  final StageEventTiming timing;
  final List<EventCondition> conditions;
  final List<EventReward> rewards;
  final String logEntry;
  final bool duel;
  final bool once;
}

class StageDefinition {
  const StageDefinition({
    required this.id,
    required this.name,
    required this.motif,
    required this.objective,
    required this.objectiveType,
    required this.objectiveRule,
    required this.lossCondition,
    required this.lossTriggers,
    required this.eventTriggers,
    required this.gimmick,
    required this.turnLimit,
    required this.width,
    required this.height,
    required this.tiles,
    required this.playerUnits,
    required this.enemyUnits,
    required this.targetWinRate,
    this.capturePoints = const <CapturePointDefinition>[],
    this.escapeZones = const <EscapeZoneDefinition>[],
    this.neutralUnits = const <UnitPlacement>[],
  });

  final int id;
  final String name;
  final String motif;
  final String objective;
  final StageObjectiveType objectiveType;
  final StageObjectiveRule objectiveRule;
  final String lossCondition;
  final List<StageLossRule> lossTriggers;
  final List<StageEventDefinition> eventTriggers;
  final String gimmick;
  final int turnLimit;
  final int width;
  final int height;
  final List<TerrainTile> tiles;
  final List<UnitPlacement> playerUnits;
  final List<UnitPlacement> enemyUnits;
  final double targetWinRate;
  final List<CapturePointDefinition> capturePoints;
  final List<EscapeZoneDefinition> escapeZones;
  final List<UnitPlacement> neutralUnits;

  OfficerProfile get boss =>
      enemyUnits.firstWhere((unit) => unit.profile.isBoss).profile;
  List<OfficerProfile> get enemySquad =>
      enemyUnits.map((unit) => unit.profile).toList(growable: false);

  StageDefinition copyWith({
    String? objective,
    String? lossCondition,
    StageObjectiveType? objectiveType,
    StageObjectiveRule? objectiveRule,
    List<StageLossRule>? lossTriggers,
    List<StageEventDefinition>? eventTriggers,
    String? gimmick,
    int? turnLimit,
    List<TerrainTile>? tiles,
    List<UnitPlacement>? playerUnits,
    List<UnitPlacement>? enemyUnits,
    List<CapturePointDefinition>? capturePoints,
    List<EscapeZoneDefinition>? escapeZones,
    List<UnitPlacement>? neutralUnits,
  }) {
    return StageDefinition(
      id: id,
      name: name,
      motif: motif,
      objective: objective ?? this.objective,
      objectiveType: objectiveType ?? this.objectiveType,
      objectiveRule: objectiveRule ?? this.objectiveRule,
      lossCondition: lossCondition ?? this.lossCondition,
      lossTriggers: lossTriggers ?? this.lossTriggers,
      eventTriggers: eventTriggers ?? this.eventTriggers,
      gimmick: gimmick ?? this.gimmick,
      turnLimit: turnLimit ?? this.turnLimit,
      width: width,
      height: height,
      tiles: tiles ?? this.tiles,
      playerUnits: playerUnits ?? this.playerUnits,
      enemyUnits: enemyUnits ?? this.enemyUnits,
      targetWinRate: targetWinRate,
      capturePoints: capturePoints ?? this.capturePoints,
      escapeZones: escapeZones ?? this.escapeZones,
      neutralUnits: neutralUnits ?? this.neutralUnits,
    );
  }

  List<ObjectiveZoneDefinition> get objectiveZones => [
    for (final point in capturePoints)
      ObjectiveZoneDefinition(
        id: point.id,
        label: point.label,
        type: ObjectiveZoneType.capture,
        tiles: [point.position],
      ),
    for (final zone in escapeZones)
      ObjectiveZoneDefinition(
        id: zone.id,
        label: zone.label,
        type: ObjectiveZoneType.escape,
        tiles: zone.tiles,
      ),
  ];

  ObjectiveZoneDefinition zoneById(String id) =>
      objectiveZones.firstWhere((zone) => zone.id == id);
}

class UnitTurnState {
  const UnitTurnState({this.hasMoved = false, this.hasActed = false});

  static const idle = UnitTurnState();

  final bool hasMoved;
  final bool hasActed;

  UnitTurnState copyWith({bool? hasMoved, bool? hasActed}) {
    return UnitTurnState(
      hasMoved: hasMoved ?? this.hasMoved,
      hasActed: hasActed ?? this.hasActed,
    );
  }
}

class CapturePointState {
  const CapturePointState({
    required this.pointId,
    required this.controller,
    required this.heldTurns,
  });

  final String pointId;
  final Faction? controller;
  final int heldTurns;

  CapturePointState copyWith({Faction? controller, int? heldTurns}) {
    return CapturePointState(
      pointId: pointId,
      controller: controller ?? this.controller,
      heldTurns: heldTurns ?? this.heldTurns,
    );
  }
}

class BattleEventRecord {
  const BattleEventRecord({
    required this.eventId,
    required this.title,
    required this.logEntry,
    required this.triggeredTurn,
    this.duel = false,
  });

  final String eventId;
  final String title;
  final String logEntry;
  final int triggeredTurn;
  final bool duel;
}

class BattleUnit {
  const BattleUnit({
    required this.id,
    required this.name,
    required this.unitClass,
    required this.faction,
    required this.x,
    required this.y,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.mobility,
    required this.range,
    required this.signature,
    required this.level,
    this.isBoss = false,
    this.isNpc = false,
    this.escaped = false,
    this.turnState = UnitTurnState.idle,
  });

  factory BattleUnit.fromPlacement(UnitPlacement placement) {
    final profile = placement.profile;
    return BattleUnit(
      id: profile.id,
      name: profile.name,
      unitClass: profile.unitClass,
      faction: profile.faction,
      x: placement.x,
      y: placement.y,
      hp: profile.maxHp,
      maxHp: profile.maxHp,
      attack: profile.attack,
      defense: profile.defense,
      mobility: profile.mobility,
      range: profile.range,
      signature: profile.signature,
      level: profile.level,
      isBoss: profile.isBoss,
      isNpc: profile.isNpc,
    );
  }

  final String id;
  final String name;
  final UnitClass unitClass;
  final Faction faction;
  final int x;
  final int y;
  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  final int mobility;
  final int range;
  final String signature;
  final int level;
  final bool isBoss;
  final bool isNpc;
  final bool escaped;
  final UnitTurnState turnState;

  bool get alive => hp > 0;
  bool get active => alive && !escaped;
  bool get isEscaped => escaped;
  bool get isLord => unitClass == UnitClass.lord;
  bool get hasMoved => turnState.hasMoved;
  bool get hasActed => turnState.hasActed;
  String get shortName => name.isEmpty ? '?' : name.substring(0, 1);
  GridPoint get position => GridPoint(x, y);

  BattleUnit copyWith({
    int? x,
    int? y,
    int? hp,
    bool? escaped,
    bool? hasMoved,
    bool? hasActed,
    UnitTurnState? turnState,
  }) {
    final nextTurnState =
        turnState ??
        this.turnState.copyWith(hasMoved: hasMoved, hasActed: hasActed);
    return BattleUnit(
      id: id,
      name: name,
      unitClass: unitClass,
      faction: faction,
      x: x ?? this.x,
      y: y ?? this.y,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      attack: attack,
      defense: defense,
      mobility: mobility,
      range: range,
      signature: signature,
      level: level,
      isBoss: isBoss,
      isNpc: isNpc,
      escaped: escaped ?? this.escaped,
      turnState: nextTurnState,
    );
  }
}

class BattleState {
  const BattleState({
    required this.stage,
    required this.turn,
    required this.phase,
    required this.units,
    required this.log,
    required this.outcome,
    required this.captureStates,
    required this.escapedUnitIds,
    required this.triggeredEvents,
    required this.rewardLog,
  });

  final StageDefinition stage;
  final int turn;
  final BattlePhase phase;
  final List<BattleUnit> units;
  final List<String> log;
  final BattleOutcome outcome;
  final Map<String, CapturePointState> captureStates;
  final List<String> escapedUnitIds;
  final List<BattleEventRecord> triggeredEvents;
  final List<String> rewardLog;

  BattleState copyWith({
    int? turn,
    BattlePhase? phase,
    List<BattleUnit>? units,
    List<String>? log,
    BattleOutcome? outcome,
    Map<String, CapturePointState>? captureStates,
    List<String>? escapedUnitIds,
    List<BattleEventRecord>? triggeredEvents,
    List<String>? rewardLog,
  }) {
    return BattleState(
      stage: stage,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      units: units ?? this.units,
      log: log ?? this.log,
      outcome: outcome ?? this.outcome,
      captureStates: captureStates ?? this.captureStates,
      escapedUnitIds: escapedUnitIds ?? this.escapedUnitIds,
      triggeredEvents: triggeredEvents ?? this.triggeredEvents,
      rewardLog: rewardLog ?? this.rewardLog,
    );
  }

  List<BattleUnit> livingUnits(Faction faction) => units
      .where((unit) => unit.faction == faction && unit.active)
      .toList(growable: false);

  List<BattleUnit> survivingUnits(Faction faction) => units
      .where((unit) => unit.faction == faction && unit.alive)
      .toList(growable: false);

  BattleUnit unitById(String id) => units.firstWhere((unit) => unit.id == id);

  bool hasTriggeredEvent(String eventId) =>
      triggeredEvents.any((event) => event.eventId == eventId);

  Set<String> get capturedZoneIds => captureStates.values
      .where((state) => state.controller == Faction.shu)
      .map((state) => state.pointId)
      .toSet();

  Map<String, Faction?> get capturePointControllers => {
    for (final entry in captureStates.entries) entry.key: entry.value.controller,
  };

  bool isZoneControlledBy(String zoneId, Faction faction) =>
      captureStates[zoneId]?.controller == faction;
}

abstract class PlayerCommand {
  const PlayerCommand();
}

class MoveUnitCommand extends PlayerCommand {
  const MoveUnitCommand({required this.unitId, required this.destination});

  final String unitId;
  final GridPoint destination;
}

class AttackUnitCommand extends PlayerCommand {
  const AttackUnitCommand({required this.attackerId, required this.targetId});

  final String attackerId;
  final String targetId;
}

class UseTacticCommand extends PlayerCommand {
  const UseTacticCommand({required this.casterId, required this.targetId});

  final String casterId;
  final String targetId;
}

class UseItemCommand extends PlayerCommand {
  const UseItemCommand({required this.userId, required this.targetId});

  final String userId;
  final String targetId;
}

class WaitUnitCommand extends PlayerCommand {
  const WaitUnitCommand({required this.unitId});

  final String unitId;
}

class EndTurnCommand extends PlayerCommand {
  const EndTurnCommand();
}

class SimulationReport {
  const SimulationReport({
    required this.outcome,
    required this.turnsUsed,
    required this.stageName,
    required this.log,
    required this.survivors,
    required this.triggeredEvents,
  });

  final BattleOutcome outcome;
  final int turnsUsed;
  final String stageName;
  final List<String> log;
  final List<BattleUnit> survivors;
  final List<BattleEventRecord> triggeredEvents;
}
