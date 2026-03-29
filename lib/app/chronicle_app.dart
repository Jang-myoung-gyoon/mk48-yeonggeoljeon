import '../src/app/app.dart';

class ChronicleApp extends NanseHeroesApp {
  ChronicleApp({super.key, super.initialRoute});

  static List<RouteSpec> get routeSpecs => NanseHeroesApp.routeSpecs;
}
