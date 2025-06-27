import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lightify/components/circle_buttons.dart';
import 'package:lightify/components/search.dart';
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
  String deviceId = "";

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
          //debugPrint("Received following message: ${msg.message}");
          final json = jsonDecode(msg.message);

          //debugPrint("Received following command: " + json['func']);

          switch (json['func']) {
            case "updateData":
              _updateData(json["body"]);
            case "setDeviceId":
              setState(() {
                deviceId = json["body"]["device_id"];
              });
          }
        },
      );

    loadHtmlFromAssets(context);
  }

  void _updateData(dynamic json) {
    setState(() {
      //TODO: investigate better error handling
      artist = json["artists"][0]["name"];
      song = json["name"];
      imgurl = json["album"]["images"][2]["url"];
    });
    return;
  }

  void _togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
    });
    _controller.runJavaScript("togglePlayback();");
  }

  void _next() {
    _controller.runJavaScript("next();");
  }

  void _prev() {
    _controller.runJavaScript("previous();");
  }

  void _setPlaying(bool val) {
    setState(() {
      isPlaying = val;
    });
  }

  String song = "Unkown Song";
  String artist = "Unkown Artist";
  String imgurl = "null";
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              SizedBox.fromSize(
                size: Size.zero,
                child: WebViewWidget(controller: _controller),
              ),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: imgurl == "null" ? Colors.blue : null,
                    decoration: imgurl != "null"
                        ? BoxDecoration(
                            image: DecorationImage(image: NetworkImage(imgurl)),
                          )
                        : null,
                    margin: EdgeInsets.all(20),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(song, style: TextStyle(fontSize: 16)),
                        Text(artist, style: TextStyle(fontSize: 12)),
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
                              icon: isPlaying ? Icons.pause : Icons.play_arrow,
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
                ],
              ),
              Search(
                token: Provider.of<AuthProvider>(context).getToken,
                deviceId: deviceId,
                pause: _togglePlay,
                prev: _prev,
                skip: _next,
                setPlaying: _setPlaying
              ),
            ],
          ),
        ),
      ),
    );
  }
}
