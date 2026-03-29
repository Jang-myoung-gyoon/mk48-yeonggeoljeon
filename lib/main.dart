import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'src/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initialRoute = NanseHeroesApp.resolveStartupRoute(
    platformRouteName: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    browserUri: Uri.base,
    isWeb: kIsWeb,
  );
  runApp(NanseHeroesApp(initialRoute: initialRoute));
}
