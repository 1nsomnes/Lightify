import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/pages/settings_page.dart';
import 'package:lightify/utilities/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({"hold_scroll_interval_ms": 200});
    await Settings.load();
  });

  test("saved values load, out-of-range values are clamped", () async {
    expect(Settings.holdScrollInterval.value, 200);
    expect(Settings.holdScrollDelay.value, 300); // not saved: default

    SharedPreferences.setMockInitialValues({"hold_scroll_delay_ms": 99999});
    await Settings.load();
    expect(Settings.holdScrollDelay.value, Settings.holdScrollDelay.max);
  });

  test("changes are clamped and saved", () async {
    final s = Settings.holdScrollInterval;
    s.nudge(-1000);
    expect(s.value, s.min);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(s.key), s.min);
    s.reset();
    expect(prefs.getInt(s.key), s.defaultValue);
  });

  testWidgets("settings page lists sections and adjusts with H/L and R", (
    tester,
  ) async {
    late PopupHostState host;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PopupHost(
            child: Builder(
              builder: (context) {
                host = PopupHost.of(context);
                return const Text("base");
              },
            ),
          ),
        ),
      ),
    );
    host.show(const SettingsPage());
    await tester.pumpAndSettle();

    expect(find.text("SCROLLING"), findsOneWidget);
    expect(find.text("Hold delay"), findsOneWidget);
    expect(find.text("300 ms"), findsOneWidget);

    // first setting is selected: L raises the hold delay by one step
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pump();
    expect(Settings.holdScrollDelay.value, 350);
    expect(find.text("350 ms"), findsOneWidget);

    // J moves to the scroll speed, H lowers it
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.pump();
    expect(Settings.holdScrollInterval.value, 190);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(Settings.holdScrollInterval.value, 150);
    expect(Settings.holdScrollDelay.value, 350);
    await tester.pumpAndSettle();
  });
}
