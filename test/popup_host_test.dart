import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/components/popup_host.dart';

void main() {
  late PopupHostState host;
  late FocusNode baseFocus;

  Future<void> pumpHost(WidgetTester tester) async {
    baseFocus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PopupHost(
            child: Builder(
              builder: (context) {
                host = PopupHost.of(context);
                return Focus(
                  focusNode: baseFocus,
                  autofocus: true,
                  child: const Text("base"),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets("popup slides in over the base page", (tester) async {
    await pumpHost(tester);
    host.show(const PopupPage(title: "First", child: SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));
    // mid-animation: popup is still partly below the window
    expect(tester.getTopLeft(find.text("First")).dy, greaterThan(100));

    await tester.pumpAndSettle();
    expect(find.text("First"), findsOneWidget);
    expect(find.text("base"), findsOneWidget);
    expect(tester.getTopLeft(find.text("First")).dy, lessThan(100));
  });

  testWidgets("a new popup replaces the previous one", (tester) async {
    await pumpHost(tester);
    host.show(const PopupPage(title: "First", child: SizedBox()));
    await tester.pumpAndSettle();

    host.show(const PopupPage(title: "Second", child: SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));
    // the old popup stays underneath while the new one slides in
    expect(find.text("First"), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text("First"), findsNothing);
    expect(find.text("Second"), findsOneWidget);
  });

  testWidgets("Esc closes back to the base page and restores focus", (
    tester,
  ) async {
    await pumpHost(tester);
    expect(baseFocus.hasFocus, isTrue);

    host.show(const PopupPage(title: "First", child: SizedBox()));
    await tester.pumpAndSettle();
    host.show(const PopupPage(title: "Second", child: SizedBox()));
    await tester.pumpAndSettle();
    expect(baseFocus.hasFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text("First"), findsNothing);
    expect(find.text("Second"), findsNothing);
    expect(host.isOpen, isFalse);
    expect(baseFocus.hasFocus, isTrue);
  });

  testWidgets("back button closes the popup", (tester) async {
    await pumpHost(tester);
    host.show(const PopupPage(title: "First", child: SizedBox()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(host.isOpen, isFalse);
  });

  testWidgets("losing window focus drops the popup immediately", (
    tester,
  ) async {
    await pumpHost(tester);
    host.show(const PopupPage(title: "First", child: SizedBox()));
    await tester.pumpAndSettle();
    host.show(const PopupPage(title: "Second", child: SizedBox()));
    // mid-replacement, so both popups are in the tree
    await tester.pump(const Duration(milliseconds: 100));

    host.onWindowBlur();
    await tester.pump();

    expect(host.isOpen, isFalse);
    expect(find.text("First"), findsNothing);
    expect(find.text("Second"), findsNothing);
    await tester.pump();
    expect(baseFocus.hasFocus, isTrue);
  });

  testWidgets("Esc without a popup calls onEscape", (tester) async {
    var escaped = 0;
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: PopupHost(
          onEscape: () => escaped++,
          child: Focus(
            focusNode: focus,
            autofocus: true,
            child: const Text("base"),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(escaped, 1);

    // with a popup open, Esc only closes the popup
    PopupHost.of(
      tester.element(find.text("base")),
    ).show(const PopupPage(title: "First", child: SizedBox()));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(escaped, 1);
    expect(find.text("First"), findsNothing);
  });
}
