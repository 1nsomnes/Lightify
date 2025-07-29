import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  static void loadHotKeys(Function restart) async {
    SpotifyService spotifyService = GetIt.instance.get<SpotifyService>();


    HotKey toggleWindow = HotKey(
      key: PhysicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      toggleWindow,
      keyDownHandler: (hotKey) {
        _toggleWindow();
      },
    );

    HotKey restartHotkey = HotKey(
      key: PhysicalKeyboardKey.keyR,
      modifiers: [HotKeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    await hotKeyManager.register(
      restartHotkey,
      keyDownHandler: (_) {
        restart();
      },
    );

    HotKey hardRestartKey = HotKey(
      key: PhysicalKeyboardKey.keyD,
      modifiers: [HotKeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    await hotKeyManager.register(
      hardRestartKey,
      keyDownHandler: (_) async {
        final storage = FlutterSecureStorage();
        await storage.delete(key:"token");
        await storage.delete(key:"refresh_token");
        //await storage.deleteAll();
        restart();
      },
    );

    HotKey breakTokenKey = HotKey(
      key: PhysicalKeyboardKey.keyT,
      modifiers: [HotKeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    await hotKeyManager.register(
      breakTokenKey,
      keyDownHandler: (_) async {
        spotifyService.setToken("break_token");
        await FlutterSecureStorage().write(key: "token", value: "break_token");
        debugPrint("attempted to break token");
      },
    );

    HotKey breakRefreshTokenKey = HotKey(
      key: PhysicalKeyboardKey.keyT,
      modifiers: [HotKeyModifier.shift, HotKeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    await hotKeyManager.register(
      breakRefreshTokenKey,
      keyDownHandler: (_) async {
        spotifyService.setToken("break_token");
        spotifyService.setRefreshToken("break_token");
        await FlutterSecureStorage().write(key: "token", value: "break_token");
        await FlutterSecureStorage().write(key: "refresh_token", value: "break_token");
        debugPrint("attempted to break both tokens");
      },
    );
  }

  static void loadPlayerhotKeys(
    Function() skip,
    Function() prev,
    Function() pause,
  ) async {
    HotKey skipKey = HotKey(
      key: PhysicalKeyboardKey.mediaTrackNext,
      scope: HotKeyScope.inapp,
    );
    HotKey prevKey = HotKey(
      key: PhysicalKeyboardKey.mediaTrackPrevious,
      scope: HotKeyScope.inapp,
    );
    HotKey pauseKey = HotKey(
      key: PhysicalKeyboardKey.mediaPlayPause,
      scope: HotKeyScope.inapp,
    );

    await hotKeyManager.register(
      skipKey,
      keyDownHandler: (_) => debugPrint("skipped"),
    );
    await hotKeyManager.register(prevKey, keyDownHandler: (_) => prev);
    await hotKeyManager.register(pauseKey, keyDownHandler: (_) => pause);
  }
}
