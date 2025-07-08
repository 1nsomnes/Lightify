import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lightify/pages/initialization_page.dart';
import 'package:lightify/providers/auth_provider.dart';
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

  await hotKeyManager.unregisterAll();
  await windowManager.ensureInitialized();

  await windowManager.setSkipTaskbar(true);

  if (Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  windowManager.addListener(BlurWindowListener());

  // RUN THE APPLICATION
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return InitializationPage();
  }
}
