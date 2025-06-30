import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

class LoadHotKeys {
  static Future<void> _toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  static void loadHotKeys(Function restart) async {
    HotKey toggleWindow = HotKey(
      key: PhysicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      scope: HotKeyScope.system, // Set as inapp-wide hotkey.
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
  }

  static void loadPlayerhotKeys(Function() skip, Function() prev, Function() pause) async {
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
