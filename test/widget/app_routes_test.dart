import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ralphthon/src/app/app.dart';

void main() {
  const routeTitles = <String, String>{
    '/': '난세영걸전',
    '/menu': '메인 메뉴',
    '/stages': '스테이지 선택',
    '/briefing': '스테이지 브리핑',
    '/formation': '편성/준비 화면',
    '/battle': '전투 메인 HUD',
    '/inspector': '전투 상세 정보창',
    '/dialogue': '스토리 대화 화면',
    '/duel': '일기토 연출',
    '/result': '결과 화면',
    '/officers': '장수 관리 화면',
    '/save': '저장/불러오기',
    '/settings': '설정 화면',
    '/game-over': '게임 오버 씬',
  };

  for (final entry in routeTitles.entries) {
    testWidgets('route ${entry.key} renders ${entry.value}', (tester) async {
      await tester.pumpWidget(NanseHeroesApp(initialRoute: entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  }

  test('unknown paths fall back to the title route spec', () {
    final resolved = NanseHeroesApp.routeByPath('/missing');

    expect(resolved.route, AppRoute.title);
    expect(resolved.label, 'SC-01 난세영걸전');
  });

  test('initial route sanitization preserves known deep links', () {
    expect(
      NanseHeroesApp.sanitizeInitialRoute('/battle'),
      AppRoute.battleHud.path,
    );
    expect(
      NanseHeroesApp.sanitizeInitialRoute('/missing'),
      AppRoute.title.path,
    );
  });

  test('startup route resolution prefers browser paths on web', () {
    expect(
      NanseHeroesApp.resolveStartupRoute(
        platformRouteName: '/',
        browserUri: Uri.parse('http://127.0.0.1:7365/battle'),
        isWeb: true,
      ),
      AppRoute.battleHud.path,
    );
    expect(
      NanseHeroesApp.resolveStartupRoute(
        platformRouteName: '/battle',
        browserUri: Uri.parse('http://127.0.0.1:7365/'),
        isWeb: false,
      ),
      AppRoute.battleHud.path,
    );
  });
}
