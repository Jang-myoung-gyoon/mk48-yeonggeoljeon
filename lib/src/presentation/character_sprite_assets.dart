import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'ui_palette_extensions.dart';

enum CharacterFacing { south, east, north, west }

extension CharacterFacingPath on CharacterFacing {
  String get pathSegment => switch (this) {
    CharacterFacing.south => 'south',
    CharacterFacing.east => 'east',
    CharacterFacing.north => 'north',
    CharacterFacing.west => 'west',
  };
}

extension CharacterFacingDirection on CharacterFacing {
  CharacterFacing get opposite => switch (this) {
    CharacterFacing.south => CharacterFacing.north,
    CharacterFacing.east => CharacterFacing.west,
    CharacterFacing.north => CharacterFacing.south,
    CharacterFacing.west => CharacterFacing.east,
  };
}

class CharacterSpriteAssets {
  const CharacterSpriteAssets._();

  static const CharacterFacing defaultFacing = CharacterFacing.south;
  static const Map<UnitClass, String> _fallbackSpriteByClass = {
    UnitClass.lord: 'liu-bei',
    UnitClass.guardian: 'guan-yu',
    UnitClass.lancer: 'zhao-yun',
    UnitClass.cavalry: 'zhang-fei',
    UnitClass.strategist: 'zhuge-liang',
    UnitClass.raider: 'zhang-fei',
    UnitClass.archer: 'zhuge-liang',
  };

  static String icon96(String spriteId) =>
      'assets/characters/$spriteId/icon/south-96.png';

  static String spriteIdForUnit(BattleUnit unit) {
    if (unit.faction == Faction.shu) {
      return unit.id;
    }
    return _fallbackSpriteByClass[unit.unitClass] ?? 'liu-bei';
  }

  static String spriteIdForProfile(OfficerProfile profile) {
    if (profile.spriteId case final spriteId?) {
      return spriteId;
    }
    if (profile.faction == Faction.shu) {
      return profile.id;
    }
    return _fallbackSpriteByClass[profile.unitClass] ?? 'liu-bei';
  }

  static String baseFrame(
    String spriteId, {
    CharacterFacing facing = defaultFacing,
  }) => 'assets/characters/$spriteId/base/${facing.pathSegment}.png';

  static String animationGif(
    String spriteId,
    String animationState, {
    CharacterFacing facing = defaultFacing,
  }) =>
      'assets/characters/$spriteId/animations/$animationState-${facing.pathSegment}.gif';

  static String animationFallbackPng(
    String spriteId,
    String animationState, {
    CharacterFacing facing = defaultFacing,
  }) =>
      'assets/characters/$spriteId/animations/$animationState-${facing.pathSegment}.png';

  static String animation(
    String spriteId,
    String animationState, {
    CharacterFacing facing = defaultFacing,
  }) => animationGif(spriteId, animationState, facing: facing);

  static CharacterFacing facingFromPoints(
    GridPoint from,
    GridPoint to, {
    CharacterFacing fallback = defaultFacing,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == 0) {
      return fallback;
    }
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? CharacterFacing.east : CharacterFacing.west;
    }
    return dy >= 0 ? CharacterFacing.south : CharacterFacing.north;
  }

  static String tile(TerrainType terrain) => 'assets/tiles/${terrain.name}.png';
}

class CharacterSpriteImage extends StatelessWidget {
  const CharacterSpriteImage({
    super.key,
    required this.assetPath,
    required this.fallback,
    this.size = 48,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final Widget fallback;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class OfficerAvatar extends StatelessWidget {
  const OfficerAvatar({super.key, required this.profile, this.size = 48});

  final OfficerProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spriteId = CharacterSpriteAssets.spriteIdForProfile(profile);
    return CharacterSpriteImage(
      assetPath: CharacterSpriteAssets.icon96(spriteId),
      size: size,
      fallback: _FallbackAvatar(
        label: profile.name,
        faction: profile.faction,
        size: size,
      ),
    );
  }
}

class OfficerSprite extends StatelessWidget {
  const OfficerSprite({
    super.key,
    required this.profile,
    this.animationState = 'idle',
    this.facing = CharacterSpriteAssets.defaultFacing,
    this.size = 64,
  });

  final OfficerProfile profile;
  final String animationState;
  final CharacterFacing facing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spriteId = CharacterSpriteAssets.spriteIdForProfile(profile);
    return CharacterSpriteImage(
      assetPath: CharacterSpriteAssets.animationGif(
        spriteId,
        animationState,
        facing: facing,
      ),
      size: size,
      fallback: CharacterSpriteImage(
        assetPath: CharacterSpriteAssets.animationFallbackPng(
          spriteId,
          animationState,
          facing: facing,
        ),
        size: size,
        fallback: CharacterSpriteImage(
          assetPath: CharacterSpriteAssets.baseFrame(spriteId, facing: facing),
          size: size,
          fallback: _FallbackAvatar(
            label: profile.name,
            faction: profile.faction,
            size: size,
          ),
        ),
      ),
    );
  }
}

class BattleUnitSprite extends StatelessWidget {
  const BattleUnitSprite({
    super.key,
    required this.unit,
    this.animationState = 'idle',
    this.facing = CharacterSpriteAssets.defaultFacing,
    this.size = 36,
  });

  final BattleUnit unit;
  final String animationState;
  final CharacterFacing facing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spriteId = CharacterSpriteAssets.spriteIdForUnit(unit);
    return CharacterSpriteImage(
      assetPath: CharacterSpriteAssets.animationGif(
        spriteId,
        animationState,
        facing: facing,
      ),
      size: size,
      fallback: CharacterSpriteImage(
        assetPath: CharacterSpriteAssets.animationFallbackPng(
          spriteId,
          animationState,
          facing: facing,
        ),
        size: size,
        fallback: CharacterSpriteImage(
          assetPath: CharacterSpriteAssets.baseFrame(spriteId, facing: facing),
          size: size,
          fallback: _FallbackAvatar(
            label: unit.name,
            faction: unit.faction,
            size: size,
          ),
        ),
      ),
    );
  }
}

class TerrainTileSprite extends StatelessWidget {
  const TerrainTileSprite({super.key, required this.terrain, this.size = 40});

  final TerrainType terrain;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CharacterSpriteImage(
      assetPath: CharacterSpriteAssets.tile(terrain),
      size: size,
      fit: BoxFit.cover,
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          color: switch (terrain) {
            TerrainType.plain => const Color(0xFF5D7043),
            TerrainType.forest => const Color(0xFF31553B),
            TerrainType.gate => const Color(0xFF6B4B2A),
            TerrainType.road => const Color(0xFF7C6A4C),
            TerrainType.river => const Color(0xFF305C77),
            TerrainType.village => const Color(0xFF8C7150),
            TerrainType.wall => const Color(0xFF4B4B4B),
          },
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.label,
    required this.faction,
    required this.size,
  });

  final String label;
  final Faction faction;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: faction.color,
      child: Text(label.isEmpty ? '?' : label.substring(0, 1)),
    );
  }
}
