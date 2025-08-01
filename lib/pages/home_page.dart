import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/circle_buttons.dart';
import 'package:lightify/components/search.dart';
import 'package:lightify/utilities/spotify/playback_state.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;
  late final SpotifyService spotifyService;
  late final StreamSubscription _playbackChangeSubscription;
  String deviceId = "";

  Future<void> loadHtmlFromAssets(BuildContext context) async {
    String html = await rootBundle.loadString('assets/player.html');
    if (context.mounted) {
      html = html.replaceAll("{token}", spotifyService.getToken);
      _controller.loadHtmlString(html);
    }
  }

  @override
  void dispose() {
    _playbackChangeSubscription.cancel();
    _controller.runJavaScript('window.stop();');
    _controller.removeJavaScriptChannel("FlutterHost");
    _controller.loadRequest(Uri.parse("about:blank"));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    spotifyService = GetIt.instance.get<SpotifyService>();
    spotifyService.updatePlayerToken = _updateToken;
    _playbackChangeSubscription = spotifyService.onPlaybackStateChanged.listen((state) {
      setState(() {
        playbackState = state;
      });
    });

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

          //debugPrint("Received following command: ${json['func']}");

          switch (json['func']) {
            case "updateData":
              _updateData(json["body"]);
            case "updateDataFromPlayer":
              spotifyService.processStateFromPlayer(json["body"]);
            case "setDeviceId":
              spotifyService.setDeviceId(json["body"]["device_id"]);
              setState(() {
                deviceId = json["body"]["device_id"];
              });
            case "authenticationFailed":
              spotifyService.attemptRefresh();
            default:
              debugPrint("unhandled function: ${json['func']}");
          }
        },
      );

    loadHtmlFromAssets(context);

    //TODO: get media keys working...
    //LoadHotKeys.loadPlayerhotKeys(_next, _prev, _togglePlay);
  }

  void _updateData(dynamic json) {
    //debugPrint("data updated: $json");
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
      playbackState.playing = !playbackState.playing;
    });

    //WARNING: this causes some lag between the pause and play button, should be smaller than the remote lag
    //TODO: temporary fix to token expiring? 
    spotifyService.getPlaybackState(notifyListeners: false).then((_) {
      _controller.runJavaScript("togglePlayback();");
    });
  }

  void _updateToken(String token) async {
    final escaped = token.replaceAll("'", r"\'");
    final setTokenString = "setToken('$escaped');";
    await _controller.runJavaScript(setTokenString);
    await _controller.runJavaScript("reconnect();");
  }

  void _next() {
    spotifyService.getPlaybackState(notifyListeners: false).then((_) {
      _controller.runJavaScript("next();");
    });
  }

  void _prev() {
    spotifyService.getPlaybackState(notifyListeners: false).then((_) {
    _controller.runJavaScript("previous();");
    });
  }

  void _toggleShuffle() {
    setState(() {
      playbackState.shuffleState =
          playbackState.shuffleState == ShuffleState.shuffleOff
          ? ShuffleState.shuffleOn
          : ShuffleState.shuffleOff;
    });
    spotifyService.setShuffleMode(playbackState.shuffleState);
  }

  void _switchRepeatMode() {
    setState(() {
      playbackState.repeatState =
          playbackState.repeatState == RepeatState.repeatOff
          ? RepeatState.repeatContext
          : playbackState.repeatState == RepeatState.repeatContext
          ? RepeatState.repeatOne
          : RepeatState.repeatOff;
    });

    spotifyService.setRepeatMode(playbackState.repeatState);
  }

  void _setPlaying(bool val) {
    setState(() {
      playbackState.playing = val;
    });
  }

  String song = "Unkown Song";
  String artist = "Unkown Artist";
  String imgurl = "null";
  PlaybackState playbackState = PlaybackState(
    playing: false,
    shuffleState: ShuffleState.shuffleOff,
    repeatState: RepeatState.repeatOff,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
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
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildCircleButton(
                          icon:
                              playbackState.shuffleState ==
                                  ShuffleState.shuffleOff
                              ? Icons.shuffle
                              : Icons.shuffle_on_rounded,
                          onPressed: _toggleShuffle,
                          size: 40,
                          backgroundColor: Colors.grey[700]!,
                        ),
                        buildCircleButton(
                          icon: Icons.skip_previous,
                          onPressed: _prev,
                          size: 40,
                          backgroundColor: Colors.grey[700]!,
                        ),
                        buildCircleButton(
                          icon: playbackState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          onPressed: _togglePlay,
                          size: 40,
                          backgroundColor: Colors.blue,
                        ),
                        buildCircleButton(
                          icon: Icons.skip_next,
                          onPressed: _next,
                          size: 40,
                          backgroundColor: Colors.grey[700]!,
                        ),
                        buildCircleButton(
                          icon:
                              playbackState.repeatState == RepeatState.repeatOff
                              ? Icons.repeat
                              : playbackState.repeatState ==
                                    RepeatState.repeatOne
                              ? Icons.repeat_one
                              : Icons.repeat_on,
                          onPressed: _switchRepeatMode,
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
            deviceId: deviceId,
            pause: _togglePlay,
            prev: _prev,
            skip: _next,
            setPlaying: _setPlaying,
            updateToken: _updateToken,
            toggleRepeat: _switchRepeatMode,
            toggleShuffle: _toggleShuffle,
          ),
        ],
      ),
    );
  }
}
