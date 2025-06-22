import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightify/components/circle_buttons.dart';
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
      html = html.replaceAll(
        "{token}",
        Provider.of<AuthProvider>(context, listen: false).getToken,
      );
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

  void _togglePlay() {
    _controller.runJavaScript("togglePlayback();");
  }

  void _next() {
    _controller.runJavaScript("next();");
  }

  void _prev() {
    _controller.runJavaScript("previous();");
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Center(
        child: Column(
          children: [
            SizedBox.fromSize(
              size: Size.zero,
              child: WebViewWidget(controller: _controller),
            ),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildCircleButton(
                  icon: Icons.skip_previous,
                  onPressed: _prev,
                  size: 40,
                  backgroundColor: Colors.grey[700]!,
                ),
                SizedBox(width: 20),
                buildCircleButton(
                  icon: Icons.play_arrow,
                  onPressed: _togglePlay,
                  size: 40,
                  backgroundColor: Colors.blue,
                ),
                SizedBox(width: 20),
                buildCircleButton(
                  icon: Icons.skip_next,
                  onPressed: _next,
                  size: 40,
                  backgroundColor: Colors.grey[700]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
