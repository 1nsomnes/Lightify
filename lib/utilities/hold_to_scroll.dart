import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightify/utilities/settings.dart';

/// How long a repeating key (J/K, the arrow keys, Shift+H/L) must be held
/// before it starts repeating (adjustable on the settings page).
Duration get holdScrollDelay =>
    Duration(milliseconds: Settings.holdScrollDelay.value);

/// How often the selection moves one item while the key stays held; smaller
/// is faster (adjustable on the settings page).
Duration get holdScrollInterval =>
    Duration(milliseconds: Settings.holdScrollInterval.value);

/// Scroll animation for a single press.
const tapScrollDuration = Duration(milliseconds: 200);

/// Runs [onMove] once when a key is pressed, then again every [interval]
/// once it has been held for [holdScrollDelay]. [deltaFor] picks the keys: it
/// returns the step for a key-down event, or 0 for keys this doesn't handle.
/// [onMove] gets the step and how long a scroll to the new spot should animate
/// (shorter while held, so a list keeps up).
class HoldToRepeat {
  HoldToRepeat({
    required this.deltaFor,
    required this.interval,
    required this.onMove,
  });

  final int Function(KeyDownEvent e) deltaFor;
  final Duration Function() interval;
  final void Function(int delta, Duration scrollDuration) onMove;

  Timer? _timer;
  LogicalKeyboardKey? _heldKey;

  /// Returns true if [e] was one of this repeater's keys and was used.
  bool handle(KeyEvent e) {
    switch (e) {
      case KeyDownEvent():
        final delta = deltaFor(e);
        if (delta == 0) return false;
        stop();
        _heldKey = e.logicalKey;
        onMove(delta, tapScrollDuration);
        _timer = Timer(holdScrollDelay, () {
          _timer = Timer.periodic(interval(), (_) => _tick(delta));
        });
        return true;
      case KeyUpEvent():
        if (e.logicalKey != _heldKey) return false;
        stop();
        return true;
      // the OS's own key repeat is ignored; our timer sets the pace
      case KeyRepeatEvent():
        return e.logicalKey == _heldKey;
    }
    return false;
  }

  void _tick(int delta) {
    // the key-up can go elsewhere (focus moved, window hidden), so check
    if (!HardwareKeyboard.instance.logicalKeysPressed.contains(_heldKey)) {
      stop();
      return;
    }
    onMove(delta, interval());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _heldKey = null;
  }

  void dispose() => stop();
}

/// Moves a list's selection on J/K or Down/Up, and keeps moving it while the
/// key is held. [onMove] gets the step (+1 / -1) and how long the scroll to the
/// new item should animate.
class HoldToScroll extends HoldToRepeat {
  HoldToScroll(void Function(int delta, Duration scrollDuration) onMove)
    : super(
        deltaFor: (e) => switch (e.logicalKey) {
          LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyJ => 1,
          LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyK => -1,
          _ => 0,
        },
        interval: () => holdScrollInterval,
        onMove: onMove,
      );
}

/// Seeks back / forward on Shift+H / Shift+L, repeating while held. [onSeek]
/// gets -1 or +1 (one seek step, from the settings).
class HoldToSeek extends HoldToRepeat {
  HoldToSeek(void Function(int direction) onSeek)
    : super(
        // read shift from the event's character: the global keyboard state
        // can still think shift is held from the hotkey that opened the window
        deltaFor: (e) => switch (e.character) {
          "H" => -1,
          "L" => 1,
          _ => 0,
        },
        interval: () => Duration(milliseconds: Settings.holdSeekInterval.value),
        onMove: (direction, _) => onSeek(direction),
      );
}
