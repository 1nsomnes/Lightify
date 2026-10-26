import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/utilities/hold_to_scroll.dart';

void main() {
  testWidgets("holding J keeps moving after the delay, release stops it", (
    tester,
  ) async {
    final moves = <int>[];
    final hold = HoldToScroll((delta, _) => moves.add(delta));
    await tester.pumpWidget(
      Focus(
        autofocus: true,
        onKeyEvent: (_, e) =>
            hold.handle(e) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: const SizedBox(),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyJ);
    expect(moves, [1]);

    // nothing more until the delay passes
    await tester.pump(holdScrollDelay - const Duration(milliseconds: 1));
    expect(moves, [1]);

    await tester.pump(const Duration(milliseconds: 1) + holdScrollInterval * 3);
    expect(moves, [1, 1, 1, 1]);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ);
    await tester.pump(holdScrollInterval * 5);
    expect(moves, [1, 1, 1, 1]);

    // a quick tap of K moves once
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pump(holdScrollDelay * 2);
    expect(moves.last, -1);
    expect(moves.length, 5);
    hold.dispose();
  });

  testWidgets("other keys are left alone", (tester) async {
    final hold = HoldToScroll((_, __) {});
    expect(
      hold.handle(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyQ,
          logicalKey: LogicalKeyboardKey.keyQ,
          timeStamp: Duration.zero,
        ),
      ),
      isFalse,
    );
  });
}
