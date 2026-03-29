import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/presentation/character_sprite_assets.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  const heroes = ['liu-bei', 'guan-yu', 'zhang-fei', 'zhao-yun', 'zhuge-liang'];
  const animations = ['idle', 'walk', 'attack', 'hit'];

  test('core officer sprite files exist for icon, base, and battle states', () {
    for (final hero in heroes) {
      expect(File(CharacterSpriteAssets.icon96(hero)).existsSync(), isTrue, reason: hero);
      expect(File(CharacterSpriteAssets.baseFrame(hero)).existsSync(), isTrue, reason: hero);
      for (final animation in animations) {
        expect(
          File(CharacterSpriteAssets.animation(hero, animation)).existsSync(),
          isTrue,
          reason: '$hero $animation',
        );
      }
    }
  });

  test('terrain tile sprites exist for all rendered terrain types', () {
    for (final terrain in TerrainType.values) {
      expect(File(CharacterSpriteAssets.tile(terrain)).existsSync(), isTrue, reason: terrain.name);
    }
  });
}
