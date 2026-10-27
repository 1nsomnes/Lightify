import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/components/now_playing.dart';

void main() {
  testWidgets("progress bar shows times and seeks where it's clicked", (
    tester,
  ) async {
    int? seekedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: SizedBox(
              width: 472,
              child: ProgressBar(
                positionMs: 61000,
                durationMs: 200000,
                positionAt: DateTime.now(),
                playing: false,
                onSeek: (ms) => seekedTo = ms,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text("1:01"), findsOneWidget);
    expect(find.text("3:20"), findsOneWidget);

    // the bar sits between two 36px time labels; click its middle
    await tester.tapAt(tester.getCenter(find.byType(ProgressBar)));
    await tester.pumpAndSettle();
    expect(seekedTo, 100000);
    expect(find.text("1:40"), findsOneWidget);
  });
}
