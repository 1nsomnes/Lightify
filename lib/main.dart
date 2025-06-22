import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lightify/pages/home_page.dart';
import 'package:lightify/pages/initialization_page.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

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
