import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lightify/utilities/window_channel.dart';

/// Playback actions the menu bar menu can trigger; set by HomePage while the
/// player exists.
class StatusMenuPlayback {
  const StatusMenuPlayback({
    required this.togglePlay,
    required this.next,
    required this.previous,
  });

  final VoidCallback togglePlay;
  final VoidCallback next;
  final VoidCallback previous;
}

/// The Lightify menu in the macOS menu bar (built natively in
/// macos/Runner/AppDelegate.swift). Clicks arrive as `menuAction` calls on the
/// window channel; [update] sends what's playing back to it.
abstract final class StatusMenu {
  static StatusMenuPlayback? _playback;
  static Map<String, Object?>? _lastSent;

  /// Handles clicks on the menu. [toggleWindow], [refresh] and [logout] work
  /// from any page; playback items only once the player is up.
  static void init({
    required VoidCallback toggleWindow,
    required VoidCallback refresh,
    required VoidCallback logout,
  }) {
    windowChannel.setMethodCallHandler((call) async {
      if (call.method != "menuAction") return;
      switch (call.arguments) {
        case "toggleWindow":
          toggleWindow();
        case "refresh":
          refresh();
        case "logout":
          logout();
        case "playPause":
          _playback?.togglePlay();
        case "next":
          _playback?.next();
        case "previous":
          _playback?.previous();
      }
    });
  }

  static set playback(StatusMenuPlayback? playback) {
    _playback = playback;
    if (playback == null) update(null);
  }

  /// Shows the playing song in the menu; null (no player) disables the
  /// playback items. Repeated identical updates are skipped.
  static void update(({String song, String artist, bool playing})? state) {
    final args = <String, Object?>{
      "hasPlayer": state != null,
      "song": state?.song,
      "artist": state?.artist,
      "playing": state?.playing ?? false,
    };
    if (mapEquals(args, _lastSent)) return;
    _lastSent = args;
    windowChannel.invokeMethod("updateStatusMenu", args).catchError((e) {
      // no native side in tests
      if (e is! MissingPluginException) debugPrint("status menu: $e");
    });
  }
}
