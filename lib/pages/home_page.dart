import 'package:flutter/material.dart';
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

  static const String _html = '''
  <!DOCTYPE html>
  <html>
   <head>
    <script>
function playBeep() {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(440, ctx.currentTime); // 440 Hz = A4
      osc.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.2); // play for 0.2 seconds
    }

      function sayHello(name) {
        document.body.innerHTML = "<h1>Hello, " + name + "!</h1>";
        // send a message back to Flutter
        FlutterHost.postMessage("Greeted " + name);

        playBeep();
      }
window.addEventListener('DOMContentLoaded', () => {
      playBeep();
    });
      playBeep();
    </script>
   </head>
   <body><h1>Waiting...</h1></body>
  </html>
  ''';

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
      ..addJavaScriptChannel(
        'FlutterHost',
        onMessageReceived: (JavaScriptMessage msg) {
          print("JS says: ${msg.message}");
        },
      )
      ..loadHtmlString(_html);

    /*_controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev'));*/
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
