import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.restoreSession();

  runApp(
    AppScope(
      notifier: appState,
      child: const WattWiseApp(),
    ),
  );
}
