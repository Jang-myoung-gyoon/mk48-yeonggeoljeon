import 'package:flutter/material.dart';

import '../data/game_data.dart';
import '../domain/models.dart';
import '../presentation/screens.dart';
import 'theme.dart';

enum AppRoute {
  title('/'),
  menu('/menu'),
  stageSelection('/stages'),
  stageBriefing('/briefing'),
  formation('/formation'),
  battleHud('/battle'),
  battleInspector('/inspector'),
  dialogue('/dialogue'),
  duel('/duel'),
  result('/result'),
  officerManagement('/officers'),
  saveLoad('/save'),
  settings('/settings'),
  gameOver('/game-over');

  const AppRoute(this.path);
  final String path;
}

class RouteSpec {
  const RouteSpec({
    required this.route,
    required this.screen,
    required this.builder,
  });

  final AppRoute route;
  final RequiredScreen screen;
  final WidgetBuilder builder;

  String get label => '${screen.code} ${screen.title}';
}

class NanseHeroesApp extends StatelessWidget {
  const NanseHeroesApp({super.key, this.initialRoute = '/'});

  final String initialRoute;

  static final List<RouteSpec> routeSpecs = [
    RouteSpec(route: AppRoute.title, screen: requiredScreens[0], builder: (_) => const TitleScreen()),
    RouteSpec(route: AppRoute.menu, screen: requiredScreens[1], builder: (_) => const MainMenuScreen()),
    RouteSpec(route: AppRoute.stageSelection, screen: requiredScreens[2], builder: (_) => const StageSelectionScreen()),
    RouteSpec(route: AppRoute.stageBriefing, screen: requiredScreens[3], builder: (_) => const StageBriefingScreen()),
    RouteSpec(route: AppRoute.formation, screen: requiredScreens[4], builder: (_) => const FormationScreen()),
    RouteSpec(route: AppRoute.battleHud, screen: requiredScreens[5], builder: (_) => const BattleHudScreen()),
    RouteSpec(route: AppRoute.battleInspector, screen: requiredScreens[6], builder: (_) => const BattleInspectorScreen()),
    RouteSpec(route: AppRoute.dialogue, screen: requiredScreens[7], builder: (_) => const DialogueScreen()),
    RouteSpec(route: AppRoute.duel, screen: requiredScreens[8], builder: (_) => const DuelScreen()),
    RouteSpec(route: AppRoute.result, screen: requiredScreens[9], builder: (_) => const ResultScreen()),
    RouteSpec(route: AppRoute.officerManagement, screen: requiredScreens[10], builder: (_) => const OfficerManagementScreen()),
    RouteSpec(route: AppRoute.saveLoad, screen: requiredScreens[11], builder: (_) => const SaveLoadScreen()),
    RouteSpec(route: AppRoute.settings, screen: requiredScreens[12], builder: (_) => const SettingsScreen()),
    RouteSpec(route: AppRoute.gameOver, screen: requiredScreens[13], builder: (_) => const GameOverScreen()),
  ];

  static RouteSpec routeByPath(String path) {
    return routeSpecs.firstWhere(
      (spec) => spec.route.path == path,
      orElse: () => routeSpecs.first,
    );
  }

  static String sanitizeInitialRoute(String? routeName) {
    final trimmed = routeName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return AppRoute.title.path;
    }

    final parsed = Uri.tryParse(trimmed);
    final path = parsed?.path.isNotEmpty == true ? parsed!.path : trimmed;
    final resolved = routeByPath(path);
    return resolved.route.path;
  }

  static String resolveStartupRoute({
    required String? platformRouteName,
    required Uri browserUri,
    required bool isWeb,
  }) {
    if (isWeb) {
      final browserPath = browserUri.path;
      if (browserPath.isNotEmpty && browserPath != AppRoute.title.path) {
        return sanitizeInitialRoute(browserPath);
      }
    }
    return sanitizeInitialRoute(platformRouteName);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '난세영걸전',
      debugShowCheckedModeBanner: false,
      theme: buildNanseTheme(),
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final spec = routeByPath(settings.name ?? AppRoute.title.path);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => InheritedGameData(
            data: GameDataRepository.instance,
            child: spec.builder(context),
          ),
        );
      },
    );
  }
}
