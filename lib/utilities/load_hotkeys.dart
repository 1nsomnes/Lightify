import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:window_manager/window_manager.dart';

const _windowChannel = MethodChannel('com.ced/window_utils');

class LoadHotKeys {
  static Future<void> _toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await _windowChannel.invokeMethod("moveToActiveDisplay");
      await windowManager.show();
      await windowManager.focus();
    }
  }

  static Future<void> _register(
    PhysicalKeyboardKey key,
    void Function() handler, {
    List<HotKeyModifier>? modifiers,
    HotKeyScope scope = HotKeyScope.inapp,
  }) {
    return hotKeyManager.register(
      HotKey(key: key, modifiers: modifiers, scope: scope),
      keyDownHandler: (_) => handler(),
    );
  }

  static void loadHotKeys(Function restart) async {
    final getIt = GetIt.instance;
    final spotifyService = getIt.get<SpotifyService>();
    final storage = getIt.get<FlutterSecureStorage>();

    await Future.wait([
      _register(
        PhysicalKeyboardKey.keyS,
        _toggleWindow,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      _register(
        PhysicalKeyboardKey.keyR,
        () => restart(),
        modifiers: [HotKeyModifier.control],
      ),
      _register(PhysicalKeyboardKey.keyD, () async {
        await Future.wait([
          storage.delete(key: "token"),
          storage.delete(key: "refresh_token"),
        ]);
        restart();
      }, modifiers: [HotKeyModifier.control]),
      _register(PhysicalKeyboardKey.keyT, () async {
        spotifyService.setToken("break_token");
        await storage.write(key: "token", value: "break_token");
        debugPrint("attempted to break token");
      }, modifiers: [HotKeyModifier.control]),
      _register(PhysicalKeyboardKey.keyT, () async {
        spotifyService.setToken("break_token");
        spotifyService.setRefreshToken("break_token");
        await Future.wait([
          storage.write(key: "token", value: "break_token"),
          storage.write(key: "refresh_token", value: "break_token"),
        ]);
        debugPrint("attempted to break both tokens");
      }, modifiers: [HotKeyModifier.shift, HotKeyModifier.control]),
      _register(
        PhysicalKeyboardKey.keyT,
        spotifyService.transferPlayback,
        modifiers: [HotKeyModifier.meta],
      ),
    ]);
  }

  static void loadPlayerhotKeys(
    Function() skip,
    Function() prev,
    Function() pause,
  ) async {
    await Future.wait([
      _register(
        PhysicalKeyboardKey.mediaTrackNext,
        () => debugPrint("skipped"),
      ),
      _register(PhysicalKeyboardKey.mediaTrackPrevious, () => prev()),
      _register(PhysicalKeyboardKey.mediaPlayPause, () => pause()),
    ]);
  }
}
