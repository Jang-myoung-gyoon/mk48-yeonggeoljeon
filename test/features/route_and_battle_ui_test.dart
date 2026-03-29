import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/app/app.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/data/game_session_controller.dart';
import 'package:ralphthon/src/data/save_slot_store.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/campaign_models.dart';
import 'package:ralphthon/src/presentation/character_sprite_assets.dart';

class _MemorySaveSlotStore implements SaveSlotStore {
  final Map<SaveSlotId, SaveSlotRecord> _records = {};

  @override
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots() async => Map.of(_records);

  @override
  Future<void> writeSlot(SaveSlotRecord record) async {
    _records[record.slotId] = record;
  }
}

GameSessionController _buildSession() => GameSessionController(
  GameDataRepository.instance,
  saveSlotStore: _MemorySaveSlotStore(),
);

void _configureTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2200);
  tester.view.devicePixelRatio = 1.0;
}

void _configureMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
}

void _seedFocusedBattle(GameSessionController session) {
  final battle = session.startSelectedStage(notify: false);
  session.updateCurrentBattle(
    battle.copyWith(
      units: [
        for (final unit in battle.units)
          if (unit.id == 'liu-bei')
            unit.copyWith(x: 1, y: 1)
          else if (unit.id == 'hua-xiong')
            unit.copyWith(x: 2, y: 1)
          else
            unit.copyWith(hp: 0),
      ],
    ),
  );
}

void _seedHealingBattle(GameSessionController session) {
  final battle = session.startSelectedStage(notify: false);
  session.updateCurrentBattle(
    battle.copyWith(
      units: [
        for (final unit in battle.units)
          if (unit.id == 'liu-bei')
            unit.copyWith(x: 1, y: 1)
          else if (unit.id == 'guan-yu')
            unit.copyWith(x: 2, y: 1, hp: 10)
          else
            unit.copyWith(hp: 0),
      ],
    ),
  );
}

void _seedTacticBattle(GameSessionController session) {
  final battle = session.startSelectedStage(notify: false);
  session.updateCurrentBattle(
    battle.copyWith(
      units: [
        for (final unit in battle.units)
          if (unit.id == 'liu-bei')
            unit.copyWith(x: 1, y: 1)
          else if (unit.id == 'hua-xiong')
            unit.copyWith(x: 3, y: 1)
          else
            unit.copyWith(hp: 0),
      ],
    ),
  );
}

bool _matchesAssetImage(Widget widget, String assetName) {
  if (widget is! Image) {
    return false;
  }
  final provider = widget.image;
  return provider is AssetImage && provider.assetName == assetName;
}

void main() {
  testWidgets('title screen CTA navigates into the main menu', (tester) async {
    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전장을 연다'));
    await tester.pumpAndSettle();

    expect(find.text('메인 메뉴'), findsWidgets);
  });

  testWidgets('battle HUD advances one round and can be reset', (tester) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/battle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('턴'), findsWidgets);
    expect(find.textContaining('1/8'), findsWidgets);
    expect(find.text('턴 종료'), findsOneWidget);

    await tester.tap(find.text('턴 종료'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2/8'), findsWidgets);

    await tester.tap(find.text('리셋'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1/8'), findsWidgets);
  });

  testWidgets(
    'battle HUD animates actions and restores idle state after attack',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      _seedFocusedBattle(session);

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/battle', sessionController: session),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animation('liu-bei', 'idle'),
          ),
        ),
        findsWidgets,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, '유비'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('공격').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('battle-cell-2-1')));
      await tester.pump();

      expect(find.text('애니메이션 상태: attack'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('애니메이션 상태: idle'), findsOneWidget);
    },
  );

  testWidgets(
    'battle HUD moves units over time instead of teleporting instantly',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      final battle = session.startSelectedStage(notify: false);
      session.updateCurrentBattle(
        battle.copyWith(
          units: [
            for (final unit in battle.units)
              if (unit.id == 'liu-bei')
                unit.copyWith(x: 1, y: 1)
              else
                unit.copyWith(hp: 0),
          ],
        ),
      );
      final currentBattle = session.currentBattle!;
      final liuBei = currentBattle.unitById('liu-bei');
      final destination =
          BattleEngine.reachableTiles(
              currentBattle,
              liuBei,
            ).where((tile) => tile != liuBei.position).toList(growable: false)
            ..sort(
              (a, b) => ((b.x - liuBei.x).abs() + (b.y - liuBei.y).abs())
                  .compareTo((a.x - liuBei.x).abs() + (a.y - liuBei.y).abs()),
            );
      expect(destination, isNotEmpty);
      final targetTile = destination.first;

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/battle', sessionController: session),
      );
      await tester.pumpAndSettle();

      final unitFinder = find.byKey(const ValueKey('battle-unit-liu-bei'));
      expect(unitFinder, findsOneWidget);

      await tester.tap(find.text('행동 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이동').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('battle-cell-${targetTile.x}-${targetTile.y}')),
      );
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.text('애니메이션 상태: walk'), findsOneWidget);
      expect(
        session.currentBattle!.unitById('liu-bei').position,
        liuBei.position,
      );

      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('애니메이션 상태: walk'), findsOneWidget);
      expect(
        session.currentBattle!.unitById('liu-bei').position,
        liuBei.position,
      );

      await tester.pumpAndSettle();

      expect(find.text('애니메이션 상태: idle'), findsOneWidget);
      expect(session.currentBattle!.unitById('liu-bei').position, targetTile);
    },
  );

  testWidgets(
    'battle HUD shows floating damage text after attack, then clears it',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      _seedFocusedBattle(session);
      final startingBattle = session.currentBattle!;
      final resolvedBattle = BattleEngine.attackUnit(
        startingBattle,
        attackerId: 'liu-bei',
        targetId: 'hua-xiong',
      );
      final expectedDamage =
          startingBattle.unitById('hua-xiong').hp -
          resolvedBattle.unitById('hua-xiong').hp;

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/battle', sessionController: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('행동 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('공격').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-cell-2-1')));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('-$expectedDamage'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('-$expectedDamage'), findsNothing);
    },
  );

  testWidgets(
    'battle HUD shows an attack impact particle on the struck target, then clears it',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      _seedFocusedBattle(session);

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/battle', sessionController: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('행동 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('공격').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-cell-2-1')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('battle-particle-attack')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 1100));

      expect(
        find.byKey(const ValueKey('battle-particle-attack')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'battle HUD shows a tactic impact particle on the struck target, then clears it',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      _seedTacticBattle(session);

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/battle', sessionController: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '유비'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('책략').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-cell-3-1')));
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        find.byKey(const ValueKey('battle-particle-tactic')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 1100));

      expect(
        find.byKey(const ValueKey('battle-particle-tactic')),
        findsNothing,
      );
    },
  );

  testWidgets('battle HUD shows unit hp bars and updates them after damage', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = _buildSession();
    _seedFocusedBattle(session);

    await tester.pumpWidget(
      NanseHeroesApp(initialRoute: '/battle', sessionController: session),
    );
    await tester.pumpAndSettle();

    final initialEnemyBar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('battle-hp-bar-hua-xiong')),
    );
    expect(initialEnemyBar.value, 1.0);
    expect(initialEnemyBar.valueColor?.value, const Color(0xFFE25555));

    await tester.tap(find.text('행동 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공격').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('battle-cell-2-1')));
    await tester.pump();

    final damagedEnemyBar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('battle-hp-bar-hua-xiong')),
    );
    expect(damagedEnemyBar.value, lessThan(1.0));
    expect(damagedEnemyBar.valueColor?.value, const Color(0xFFE25555));
    expect(find.byKey(const ValueKey('battle-hp-bar-liu-bei')), findsOneWidget);
  });

  testWidgets(
    'battle HUD shows floating heal text after item use, then clears it',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      _seedHealingBattle(session);
      final startingBattle = session.currentBattle!;
      final resolvedBattle = BattleEngine.useItem(
        startingBattle,
        userId: 'liu-bei',
        targetId: 'guan-yu',
      );
      final expectedHeal =
          resolvedBattle.unitById('guan-yu').hp -
          startingBattle.unitById('guan-yu').hp;

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/battle', sessionController: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('행동 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('도구').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle-cell-2-1')));
      await tester.pump();

      expect(find.text('+$expectedHeal'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('+$expectedHeal'), findsNothing);
    },
  );

  testWidgets('battle HUD renders enemy sprites with reused character assets', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = _buildSession();
    _seedFocusedBattle(session);

    await tester.pumpWidget(
      NanseHeroesApp(initialRoute: '/battle', sessionController: session),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => _matchesAssetImage(
          widget,
          CharacterSpriteAssets.animation('zhang-fei', 'idle'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('battle HUD exposes the manual command set from the PRD', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/battle'));
    await tester.pumpAndSettle();

    expect(find.text('턴 종료'), findsOneWidget);
    expect(find.text('리셋'), findsOneWidget);
    expect(find.text('커맨드 버튼'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '유비'));
    await tester.pumpAndSettle();

    expect(find.text('유비 행동 선택'), findsOneWidget);

    for (final label in ['이동', '공격', '책략', '도구', '대기']) {
      expect(find.text(label), findsWidgets);
    }

    expect(find.text('행동 메뉴 정책'), findsOneWidget);
    expect(
      find.textContaining('이동 / 공격 / 책략 / 도구 / 대기 / 턴 종료'),
      findsOneWidget,
    );
  });

  testWidgets(
    'battle HUD renders the key tactical sections from the test spec',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(NanseHeroesApp(initialRoute: '/battle'));
      await tester.pumpAndSettle();

      for (final label in ['전장 타일맵', '선택 유닛 패널', '행동 로그']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('battle HUD action popup switches command mode from unit tap', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/battle'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '유비'));
    await tester.pumpAndSettle();

    expect(find.text('유비 행동 선택'), findsOneWidget);

    await tester.tap(find.text('공격').last);
    await tester.pumpAndSettle();

    expect(find.text('유비 행동 선택'), findsNothing);
    expect(find.textContaining('현재 모드: 공격 목표 선택'), findsOneWidget);
  });

  testWidgets('stage selection renders all 10 campaign entries', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/stages'));
    await tester.pumpAndSettle();

    expect(find.text('Stage 1. 도원결의의 맹세'), findsOneWidget);
    expect(find.text('Stage 10. 형주 진입'), findsOneWidget);
  });

  testWidgets(
    'stage selection allows briefing access for late stages without prior clears',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(NanseHeroesApp(initialRoute: '/stages'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '브리핑').last);
      await tester.pumpAndSettle();

      expect(find.text('스테이지 브리핑'), findsWidgets);
      expect(find.text('형주 진입'), findsOneWidget);
    },
  );

  testWidgets(
    'officer management reflects currently unlocked officer progress',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        NanseHeroesApp(
          initialRoute: '/officers',
          sessionController: _buildSession(),
        ),
      );
      await tester.pumpAndSettle();

      for (final officer in ['유비', '관우', '장비']) {
        expect(find.textContaining('$officer ·'), findsOneWidget);
      }
      expect(find.textContaining('조운 ·'), findsNothing);
      expect(find.textContaining('제갈량 ·'), findsNothing);
      expect(find.textContaining('합류 Stage 1'), findsNWidgets(3));
    },
  );

  testWidgets(
    'save/load screen persists slot labels through the live session store',
    (tester) async {
      _configureTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = _buildSession();
      session.selectStage(4);

      await tester.pumpWidget(
        NanseHeroesApp(initialRoute: '/save', sessionController: session),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('저장').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Stage 4'), findsOneWidget);

      session.selectStage(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('불러오기').first);
      await tester.pumpAndSettle();

      expect(session.campaignState.selectedStageId, 4);
    },
  );

  testWidgets('result screen reflects the latest applied battle summary', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = _buildSession();
    session.selectStage(10);
    final battle = session.startSelectedStage(notify: false);
    final resolved = BattleEngine.resolveState(
      battle.copyWith(
        units: [
          for (final unit in battle.units)
            if (unit.id == 'liu-bei')
              unit.copyWith(x: 7, y: 2)
            else if (unit.id == 'guan-yu')
              unit.copyWith(x: 6, y: 5)
            else if (unit.id == 'allied-archer')
              unit.copyWith(hp: 0)
            else
              unit,
        ],
      ),
    );
    session.updateCurrentBattle(resolved);

    await tester.pumpWidget(
      NanseHeroesApp(initialRoute: '/result', sessionController: session),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('형주 군량 200석'), findsOneWidget);
    expect(find.textContaining('Stage 10'), findsOneWidget);
    expect(find.text('정산 적용'), findsOneWidget);
  });

  const mobileRoutes = <String, String>{
    '/': '난세영걸전',
    '/stages': '스테이지 선택',
    '/battle': '전투 메인 HUD',
    '/dialogue': '스토리 대화 화면',
    '/result': '결과 화면',
  };

  for (final entry in mobileRoutes.entries) {
    testWidgets('mobile viewport keeps ${entry.key} stable', (tester) async {
      _configureMobileViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(NanseHeroesApp(initialRoute: entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
