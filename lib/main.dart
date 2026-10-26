import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/pages/initialization_page.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class BlurWindowListener with WindowListener {
  @override
  void onWindowBlur() {
    windowManager.hide();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ensure these all started so any service that may need them will be able to
  final getIt = GetIt.instance;
  final authProvider = AuthProvider();
  const storage = FlutterSecureStorage();
  getIt.registerSingleton<AuthProvider>(authProvider);
  getIt.registerSingleton<FlutterSecureStorage>(storage);

  getIt.registerLazySingleton<SpotifyService>(
    () => SpotifyService(authProvider: authProvider, storage: storage),
  );

  await Future.wait([
    hotKeyManager.unregisterAll(),
    windowManager
        .ensureInitialized()
        .then((_) => windowManager.setSkipTaskbar(true)),
  ]);

  if (Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  windowManager.addListener(BlurWindowListener());

  // RUN THE APPLICATION
  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const InitializationPage();
  }
}
