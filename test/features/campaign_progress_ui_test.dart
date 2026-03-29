import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/app/app.dart';
import 'package:ralphthon/src/data/game_data.dart';
import 'package:ralphthon/src/data/game_session_controller.dart';
import 'package:ralphthon/src/domain/battle_engine.dart';
import 'package:ralphthon/src/domain/campaign_models.dart';
import 'package:ralphthon/src/domain/models.dart';

void main() {
  testWidgets('formation screen toggles the selected roster from campaign state', (
    tester,
  ) async {
    await tester.pumpWidget(NanseHeroesApp(initialRoute: '/formation'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('출전 중'), findsNWidgets(3));

    await tester.tap(find.widgetWithText(FilterChip, '출전 중').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('출전 중'), findsNWidgets(2));
    expect(find.text('대기'), findsOneWidget);
  });

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

  testWidgets('result screen renders battle rewards from the session controller', (
    tester,
  ) async {
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
  });
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
