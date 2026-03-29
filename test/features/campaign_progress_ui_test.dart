import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/app/app.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/data/game_session_controller.dart';
import 'package:ralphthon/src/data/save_slot_store.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/campaign_models.dart';
import 'package:ralphthon/src/domain/models.dart';
import 'package:ralphthon/src/presentation/character_sprite_assets.dart';

bool _matchesAssetImage(Widget widget, String assetName) {
  if (widget is! Image) {
    return false;
  }
  final provider = widget.image;
  return provider is AssetImage && provider.assetName == assetName;
}

void main() {
  testWidgets('stage briefing renders roster visuals from character assets', (
    tester,
  ) async {
    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/briefing'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate(
        (widget) => _matchesAssetImage(
          widget,
          CharacterSpriteAssets.animationGif('liu-bei', 'idle'),
        ),
      ),
      findsWidgets,
    );
  });

  testWidgets(
    'formation screen toggles the selected roster from campaign state',
    (tester) async {
      await tester.pumpWidget(NanseHeroesApp(initialRoute: '/formation'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('출전 중'), findsNWidgets(3));

      await tester.tap(find.widgetWithText(FilterChip, '출전 중').first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('출전 중'), findsNWidgets(2));
      expect(find.text('대기'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animationGif('liu-bei', 'idle'),
          ),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animationGif('zhang-fei', 'idle'),
          ),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('save/load screen renders live slot metadata from the session', (
    tester,
  ) async {
    final controller = GameSessionController(
      GameDataRepository.instance,
      saveSlotStore: _MemoryStore(),
    );
    final app = NanseHeroesApp(
      initialRoute: '/save',
      sessionController: controller,
    );

    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 100));

    controller.selectStage(4);
    await controller.saveToSlot(SaveSlotId.slot1);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Stage 4 · 서주 구원'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '불러오기'), findsNWidgets(3));
    expect(find.widgetWithText(FilledButton, '저장'), findsNWidgets(3));
  });

  testWidgets(
    'result screen renders battle rewards from the session controller',
    (tester) async {
      final controller = GameSessionController(
        GameDataRepository.instance,
        saveSlotStore: _MemoryStore(),
      );
      final app = NanseHeroesApp(
        initialRoute: '/result',
        sessionController: controller,
      );

      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 100));

      controller.selectStage(2);
      final battle = controller.startSelectedStage(notify: false);
      final duelResolved = BattleEngine.resolveState(
        battle.copyWith(
          units: [
            for (final unit in battle.units)
              if (unit.id == 'guan-yu')
                unit.copyWith(x: 6, y: 3)
              else if (unit.id == 'hua-xiong')
                unit.copyWith(x: 7, y: 3)
              else
                unit,
          ],
        ),
        timings: const {StageEventTiming.duel, StageEventTiming.battleEnd},
      );
      controller.updateCurrentBattle(duelResolved);

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('정산 적용'), findsOneWidget);
      expect(find.textContaining('경험치 +100'), findsOneWidget);
      expect(find.textContaining('azure-spoils'), findsOneWidget);
    },
  );

  testWidgets(
    'duel screen reuses character assets and advances animation beats',
    (tester) async {
      await tester.pumpWidget(NanseHeroesApp(initialRoute: '/duel'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animationGif(
              'guan-yu',
              'idle',
              facing: CharacterFacing.east,
            ),
          ),
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animationGif(
              'zhang-fei',
              'idle',
              facing: CharacterFacing.west,
            ),
          ),
        ),
        findsWidgets,
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animationGif(
              'guan-yu',
              'attack',
              facing: CharacterFacing.east,
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => _matchesAssetImage(
            widget,
            CharacterSpriteAssets.animationGif(
              'zhang-fei',
              'hit',
              facing: CharacterFacing.west,
            ),
          ),
        ),
        findsOneWidget,
      );
    },
  );
}

class _MemoryStore implements SaveSlotStore {
  final Map<SaveSlotId, SaveSlotRecord> _records = {};

  @override
  Future<Map<SaveSlotId, SaveSlotRecord>> loadSlots() async =>
      Map<SaveSlotId, SaveSlotRecord>.from(_records);

  @override
  Future<void> writeSlot(SaveSlotRecord record) async {
    _records[record.slotId] = record;
  }
}
