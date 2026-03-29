import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/domain/models.dart';
import 'package:ralphthon/src/presentation/character_sprite_assets.dart';

void main() {
  const enemyRaider = BattleUnit(
    id: 'hua-xiong',
    name: '화웅',
    unitClass: UnitClass.raider,
    faction: Faction.enemy,
    x: 4,
    y: 3,
    hp: 28,
    maxHp: 28,
    attack: 12,
    defense: 8,
    mobility: 3,
    range: 1,
    signature: '높은 공격력',
    level: 15,
  );

  const neutralArcher = BattleUnit(
    id: 'escort-archer',
    name: '호위병',
    unitClass: UnitClass.archer,
    faction: Faction.neutral,
    x: 2,
    y: 1,
    hp: 12,
    maxHp: 12,
    attack: 3,
    defense: 2,
    mobility: 2,
    range: 2,
    signature: '지원 사격',
    level: 4,
  );

  test('hero units keep their own sprite ids', () {
    const hero = BattleUnit(
      id: 'liu-bei',
      name: '유비',
      unitClass: UnitClass.lord,
      faction: Faction.shu,
      x: 0,
      y: 0,
      hp: 24,
      maxHp: 24,
      attack: 8,
      defense: 7,
      mobility: 3,
      range: 1,
      signature: '지원형',
      level: 12,
    );

    expect(CharacterSpriteAssets.spriteIdForUnit(hero), 'liu-bei');
  });

  test('enemy units reuse an existing hero sprite based on their class', () {
    expect(CharacterSpriteAssets.spriteIdForUnit(enemyRaider), 'zhang-fei');
    expect(CharacterSpriteAssets.spriteIdForUnit(neutralArcher), 'zhuge-liang');
  });

  test('battle animation paths target facing-specific gif assets', () {
    expect(
      CharacterSpriteAssets.animationGif(
        'guan-yu',
        'attack',
        facing: CharacterFacing.east,
      ),
      'assets/characters/guan-yu/animations/attack-east.gif',
    );
  });
}
