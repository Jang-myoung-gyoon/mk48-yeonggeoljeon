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

class StageDefinition {
  const StageDefinition({
    required this.id,
    required this.name,
    required this.motif,
    required this.objective,
    required this.lossCondition,
    required this.gimmick,
    required this.turnLimit,
    required this.width,
    required this.height,
    required this.tiles,
    required this.playerUnits,
    required this.enemyUnits,
    required this.targetWinRate,
  });

  final int id;
  final String name;
  final String motif;
  final String objective;
  final String lossCondition;
  final String gimmick;
  final int turnLimit;
  final int width;
  final int height;
  final List<TerrainTile> tiles;
  final List<UnitPlacement> playerUnits;
  final List<UnitPlacement> enemyUnits;
  final double targetWinRate;

  OfficerProfile get boss =>
      enemyUnits.firstWhere((unit) => unit.profile.isBoss).profile;
  List<OfficerProfile> get enemySquad =>
      enemyUnits.map((unit) => unit.profile).toList(growable: false);
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
  final UnitTurnState turnState;

  bool get alive => hp > 0;
  bool get isLord => unitClass == UnitClass.lord;
  bool get hasMoved => turnState.hasMoved;
  bool get hasActed => turnState.hasActed;
  String get shortName => name.isEmpty ? '?' : name.substring(0, 1);
  GridPoint get position => GridPoint(x, y);

  BattleUnit copyWith({
    int? x,
    int? y,
    int? hp,
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
  });

  final StageDefinition stage;
  final int turn;
  final BattlePhase phase;
  final List<BattleUnit> units;
  final List<String> log;
  final BattleOutcome outcome;

  BattleState copyWith({
    int? turn,
    BattlePhase? phase,
    List<BattleUnit>? units,
    List<String>? log,
    BattleOutcome? outcome,
  }) {
    return BattleState(
      stage: stage,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      units: units ?? this.units,
      log: log ?? this.log,
      outcome: outcome ?? this.outcome,
    );
  }

  List<BattleUnit> livingUnits(Faction faction) => units
      .where((unit) => unit.faction == faction && unit.alive)
      .toList(growable: false);

  BattleUnit unitById(String id) => units.firstWhere((unit) => unit.id == id);
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
  });

  final BattleOutcome outcome;
  final int turnsUsed;
  final String stageName;
  final List<String> log;
  final List<BattleUnit> survivors;
}
