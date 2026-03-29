import 'package:flutter/material.dart';

import '../domain/models.dart';

extension TerrainPalette on TerrainType {
  Color get color => switch (this) {
    TerrainType.plain => const Color(0xFF5E6D3D),
    TerrainType.forest => const Color(0xFF2E5939),
    TerrainType.gate => const Color(0xFF8C6A46),
    TerrainType.road => const Color(0xFF7A5E3A),
    TerrainType.river => const Color(0xFF275E7A),
    TerrainType.village => const Color(0xFF8D6C57),
    TerrainType.wall => const Color(0xFF6B6764),
  };
}

extension FactionPalette on Faction {
  Color get color => switch (this) {
    Faction.shu => const Color(0xFF3B8C73),
    Faction.enemy => const Color(0xFF9A3F3F),
    Faction.neutral => const Color(0xFF8B7B5A),
  };
}
