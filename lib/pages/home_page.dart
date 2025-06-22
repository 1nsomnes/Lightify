import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;

  Future<void> loadHtmlFromAssets(BuildContext context) async {
    String html = await rootBundle.loadString('assets/player.html');
    if (context.mounted) {
      html = html.replaceAll("{token}", Provider.of<AuthProvider>(context, listen: false).getToken);
      _controller.loadHtmlString(html);
    }
  }

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setOnConsoleMessage((JavaScriptConsoleMessage msg) {
        debugPrint('[WebView][JS:${msg.level}] ${msg.message} ');
      })
      ..addJavaScriptChannel(
        'FlutterHost',
        onMessageReceived: (JavaScriptMessage msg) {
          debugPrint("JS says: ${msg.message}");
        },
      );

    loadHtmlFromAssets(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /*home: Scaffold(
        body: Expanded(child: WebViewWidget(controller: _controller)),
      ),*/
      home: Center(
        child: Column(
          children: [
            Expanded(child: WebViewWidget(controller: _controller)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: () {
                  // 1) call the JS function with an argument
                  _controller.runJavaScript("sayHello('Flutter Dev');");
                },
                child: const Text('Call JS sayHello()'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
