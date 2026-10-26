import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/now_playing.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/components/search.dart';
import 'package:lightify/utilities/spotify/playback_state.dart';
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:lightify/utilities/window_channel.dart';
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

  Future<void> loadHtmlFromAssets() async {
    final html = await rootBundle.loadString('assets/player.html');
    if (mounted) {
      _controller.loadHtmlString(
        html
            .replaceAll("{token}", spotifyService.getToken)
            .replaceAll("{name}", SpotifyService.playerName),
      );
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
    _playbackChangeSubscription = spotifyService.onPlaybackStateChanged.listen((
      state,
    ) {
      if (state.playing == playbackState.playing &&
          state.shuffleState == playbackState.shuffleState &&
          state.repeatState == playbackState.repeatState) {
        return;
      }
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
              _updateProgress(json["body"]);
            case "setDeviceId":
              spotifyService.setDeviceId(json["body"]["device_id"]);
            case "authenticationFailed":
              spotifyService.attemptRefresh();
            default:
              debugPrint("unhandled function: ${json['func']}");
          }
        },
      );

    loadHtmlFromAssets();

    //TODO: get media keys working...
    //LoadHotKeys.loadPlayerhotKeys(_next, _prev, _togglePlay);
  }

  void _updateData(dynamic json) {
    //debugPrint("data updated: $json");
    //TODO: investigate better error handling
    final String newArtist = json["artists"][0]["name"];
    final String newSong = json["name"];
    final url = _artworkUrl(json["album"]?["images"]);
    final newImgurl = url.isEmpty ? "null" : url;
    if (newArtist == artist && newSong == song && newImgurl == imgurl) return;
    setState(() {
      artist = newArtist;
      song = newSong;
      imgurl = newImgurl;
    });
  }

  // the player's state includes where the song is; NowPlaying advances the bar
  // from there while it plays
  void _updateProgress(dynamic state) {
    final position = state["position"];
    final duration = state["duration"];
    if (position is! num || duration is! num) return;
    setState(() {
      _positionMs = position.toInt();
      _durationMs = duration.toInt();
      _positionAt = DateTime.now();
    });
  }

  // a mid-sized cover (~300px) stays sharp at the player's size; Spotify lists
  // images largest first
  static String _artworkUrl(dynamic images) {
    if (images is! List || images.isEmpty) return "";
    final image = images.length > 1 ? images[1] : images.first;
    return image["url"] ?? ProcessResponse.smallestImageUrl(images);
  }

  void _seek(int ms) {
    setState(() {
      _positionMs = ms;
      _positionAt = DateTime.now();
    });
    _controller.runJavaScript("seek($ms);");
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
    // reconnecting doesn't re-fire `ready`, so pick up a changed id here
    spotifyService.refreshDeviceId();
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
    if (playbackState.playing == val) return;
    setState(() {
      playbackState.playing = val;
    });
  }

  String song = "Nothing playing";
  String artist = "Pick something below";
  String imgurl = "null";
  int _positionMs = 0;
  int _durationMs = 0;
  DateTime _positionAt = DateTime.now();
  PlaybackState playbackState = PlaybackState(
    playing: false,
    shuffleState: ShuffleState.shuffleOff,
    repeatState: RepeatState.repeatOff,
  );

  @override
  Widget build(BuildContext context) {
    return PopupHost(
      onEscape: () => windowChannel.invokeMethod("hideWindow"),
      child: Center(
        child: Column(
          children: [
            SizedBox.fromSize(
              size: Size.zero,
              child: WebViewWidget(controller: _controller),
            ),
            NowPlaying(
              song: song,
              artist: artist,
              imageUrl: imgurl == "null" ? "" : imgurl,
              state: playbackState,
              positionMs: _positionMs,
              durationMs: _durationMs,
              positionAt: _positionAt,
              onTogglePlay: _togglePlay,
              onNext: _next,
              onPrevious: _prev,
              onShuffle: _toggleShuffle,
              onRepeat: _switchRepeatMode,
              onSeek: _seek,
            ),
            // fill only the space left in the window so the list scrolls
            // instead of overflowing
            Expanded(
              child: Search(
                pause: _togglePlay,
                prev: _prev,
                skip: _next,
                setPlaying: _setPlaying,
                updateToken: _updateToken,
                toggleRepeat: _switchRepeatMode,
                toggleShuffle: _toggleShuffle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
