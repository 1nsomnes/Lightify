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

  static void loadHotKeys() async {
    HotKey hotKey = HotKey(
      key: PhysicalKeyboardKey.keyS,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      scope: HotKeyScope.system, // Set as inapp-wide hotkey.
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        _toggleWindow();
      },
    );
  }

  static void loadPlayerhotKeys(void skip, void prev, void pause) async {
    HotKey skipKey = HotKey(
      key: PhysicalKeyboardKey.keyN,
      scope: HotKeyScope.inapp,
    );
    HotKey prevKey = HotKey(
      key: PhysicalKeyboardKey.keyP,
      scope: HotKeyScope.inapp,
    );
    HotKey pauseKey = HotKey(
      key: PhysicalKeyboardKey.space,
      scope: HotKeyScope.inapp,
    );

    await hotKeyManager.register(skipKey, keyDownHandler: (_) => debugPrint("skipped"));
    await hotKeyManager.register(prevKey, keyDownHandler: (_) => prev);
    await hotKeyManager.register(pauseKey, keyDownHandler: (_) => pause);
  }
}
