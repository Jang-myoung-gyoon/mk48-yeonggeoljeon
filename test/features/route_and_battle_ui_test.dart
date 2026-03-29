import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/app/app.dart';

void _configureTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2200);
  tester.view.devicePixelRatio = 1.0;
}

void _configureMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  testWidgets('title screen CTA navigates into the main menu', (tester) async {
    await tester.pumpWidget(const NanseHeroesApp(initialRoute: '/'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('전장을 연다'));
    await tester.pumpAndSettle();

    expect(find.text('메인 메뉴'), findsWidgets);
  });

  testWidgets('battle HUD advances one round and can be reset', (tester) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NanseHeroesApp(initialRoute: '/battle'));
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

  testWidgets('battle HUD exposes the manual command set from the PRD', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NanseHeroesApp(initialRoute: '/battle'));
    await tester.pumpAndSettle();

    expect(find.text('턴 종료'), findsOneWidget);
    expect(find.text('리셋'), findsOneWidget);

    for (final label in ['이동', '공격', '책략', '도구', '대기']) {
      expect(find.text(label), findsOneWidget);
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

      await tester.pumpWidget(const NanseHeroesApp(initialRoute: '/battle'));
      await tester.pumpAndSettle();

      for (final label in ['전장 타일맵', '선택 유닛 패널', '커맨드 버튼', '행동 로그']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('stage selection renders all 10 campaign entries', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NanseHeroesApp(initialRoute: '/stages'));
    await tester.pumpAndSettle();

    expect(find.text('Stage 1. 도원결의의 맹세'), findsOneWidget);
    expect(find.text('Stage 10. 형주 진입'), findsOneWidget);
  });

  testWidgets('officer management renders all five Shu officer cards', (
    tester,
  ) async {
    _configureTallViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NanseHeroesApp(initialRoute: '/officers'));
    await tester.pumpAndSettle();

    for (final officer in ['유비', '관우', '장비', '조운', '제갈량']) {
      expect(find.textContaining('$officer ·'), findsOneWidget);
    }
    expect(find.textContaining('남향 아이콘 규격 96×96'), findsNWidgets(5));
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
