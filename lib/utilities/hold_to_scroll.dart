import 'dart:async';

import 'package:flutter/services.dart';

/// How long J/K (or the arrow keys) must be held before the selection starts
/// moving on its own.
const holdScrollDelay = Duration(milliseconds: 300);

/// How often the selection moves one item while the key stays held; smaller
/// is faster.
const holdScrollInterval = Duration(milliseconds: 150);

/// Scroll animation for a single press.
const tapScrollDuration = Duration(milliseconds: 200);

/// Moves a list's selection on J/K or Down/Up, and keeps moving it while the
/// key is held. [onMove] gets the step (+1 / -1) and how long the scroll to the
/// new item should animate (shorter while held, so the list keeps up).
class HoldToScroll {
  HoldToScroll(this.onMove);

  final void Function(int delta, Duration scrollDuration) onMove;

  Timer? _timer;
  LogicalKeyboardKey? _heldKey;

  static int _deltaFor(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyJ => 1,
    LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyK => -1,
    _ => 0,
  };

  /// Returns true if [e] was a scroll key (down, repeat or up) and was used.
  bool handle(KeyEvent e) {
    final delta = _deltaFor(e.logicalKey);
    if (delta == 0) return false;
    switch (e) {
      case KeyDownEvent():
        stop();
        _heldKey = e.logicalKey;
        onMove(delta, tapScrollDuration);
        _timer = Timer(holdScrollDelay, () {
          _timer = Timer.periodic(holdScrollInterval, (_) => _tick(delta));
        });
      case KeyUpEvent():
        if (e.logicalKey == _heldKey) stop();
      // the OS's own key repeat is ignored; our timer sets the pace
      case KeyRepeatEvent():
        break;
    }
    return true;
  }

  void _tick(int delta) {
    // the key-up can go elsewhere (focus moved, window hidden), so check
    if (!HardwareKeyboard.instance.logicalKeysPressed.contains(_heldKey)) {
      stop();
      return;
    }
    onMove(delta, holdScrollInterval);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _heldKey = null;
  }

  void dispose() => stop();
}
