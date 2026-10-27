import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/pages/settings_page.dart';
import 'package:lightify/utilities/settings.dart';
import 'package:lightify/utilities/update_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test("versions compare by part, ignoring a v prefix and build numbers", () {
    expect(UpdateCheck.compareVersions("v1.0", "1.0.0"), 0);
    expect(UpdateCheck.compareVersions("v1.0.1", "1.0.0"), greaterThan(0));
    expect(UpdateCheck.compareVersions("v1.2.0", "1.10.0"), lessThan(0));
    expect(UpdateCheck.compareVersions("v2.0.0", "1.9.9+40"), greaterThan(0));
    expect(UpdateCheck.compareVersions("1.0.0+3", "1.0.0+1"), 0);
  });

  Future<void> showSettings(WidgetTester tester, VersionInfo info) async {
    SharedPreferences.setMockInitialValues({});
    await Settings.load();
    UpdateCheck.reset();
    UpdateCheck.checker = () async => info;
    late PopupHostState host;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PopupHost(
            child: Builder(
              builder: (context) {
                host = PopupHost.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    host.show(const SettingsPage());
    await tester.pumpAndSettle();
  }

  tearDown(UpdateCheck.reset);

  testWidgets("settings footer shows the version and up to date", (
    tester,
  ) async {
    await showSettings(
      tester,
      const VersionInfo("1.0.0", UpdateStatus.upToDate),
    );
    final label = tester.widget<Text>(find.text("up to date"));
    expect(label.style!.color, const Color(0xFF1DB954));
    expect(find.text("v1.0.0"), findsOneWidget);
    expect(find.text("out of date"), findsNothing);
  });

  testWidgets("an older version is marked out of date in red", (tester) async {
    await showSettings(
      tester,
      const VersionInfo(
        "1.0.0",
        UpdateStatus.outOfDate,
        releaseUrl: "https://github.com/1nsomnes/Lightify/releases/tag/v1.1.0",
      ),
    );
    final label = tester.widget<Text>(find.text("out of date"));
    expect(label.style!.color, const Color(0xFFE5534B));
    expect(label.style!.decoration, TextDecoration.underline);
    expect(find.text("v1.0.0"), findsOneWidget);
    // the status comes first
    expect(
      tester.getTopLeft(find.text("out of date")).dx,
      lessThan(tester.getTopLeft(find.text("v1.0.0")).dx),
    );
  });

  testWidgets("without a result from GitHub only the version shows", (
    tester,
  ) async {
    await showSettings(
      tester,
      const VersionInfo("1.0.0", UpdateStatus.unknown),
    );
    expect(find.text("v1.0.0"), findsOneWidget);
    expect(find.textContaining("date"), findsNothing);
  });
}
