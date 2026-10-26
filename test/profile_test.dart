import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/components/profile_view.dart';
import 'package:lightify/pages/profile_pages.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';

SearchItem item(String name, {String? creator}) => SearchItem(
  name: name,
  artist: "sub $name",
  imgUrl: "",
  ctxUri: "spotify:track:$name",
  creatorUri: creator,
);

void main() {
  setUpAll(() {
    GetIt.instance.registerSingleton(
      SpotifyService(
        storage: const FlutterSecureStorage(),
        authProvider: AuthProvider(),
      ),
    );
  });

  group("parsing links items to their artist/owner", () {
    test("tracks and albums link to their first artist", () {
      final list = <SearchItem>[];
      ProcessResponse.processTracksJson([
        {
          "name": "Atmosphere",
          "uri": "spotify:track:1",
          "album": {"images": []},
          "artists": [
            {"name": "Joy Division", "uri": "spotify:artist:jd"},
            {"name": "Other", "uri": "spotify:artist:other"},
          ],
        },
      ], list);
      expect(list.single.creatorUri, "spotify:artist:jd");
    });

    test("playlists link to their owner", () {
      final list = <SearchItem>[];
      ProcessResponse.processPlaylistsJson([
        {
          "name": "fall 26",
          "uri": "spotify:playlist:p",
          "images": [],
          "owner": {"display_name": "Cedric", "uri": "spotify:user:ced"},
        },
      ], list);
      expect(list.single.creatorUri, "spotify:user:ced");
    });
  });

  late PopupHostState host;

  Future<void> pumpHost(WidgetTester tester) async {
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
  }

  ProfileView artistView() => ProfileView(
    kind: "Artist",
    icon: Icons.verified,
    load: () async => ProfileData(
      name: "Joy Division",
      imageUrl: "",
      details: "1,234 followers",
      sections: [
        ProfileSection(
          title: "Popular",
          numbered: true,
          items: [item("a"), item("b", creator: "spotify:user:someone")],
        ),
        ProfileSection(title: "Discography", items: [item("c")]),
        const ProfileSection(title: "Empty", items: []),
      ],
    ),
  );

  testWidgets("profile shows the kind badge, name and sections", (
    tester,
  ) async {
    await pumpHost(tester);
    host.show(artistView());
    await tester.pumpAndSettle();

    expect(find.text("ARTIST"), findsOneWidget);
    expect(find.text("Joy Division"), findsOneWidget);
    expect(find.text("1,234 followers"), findsOneWidget);
    expect(find.text("Popular"), findsOneWidget);
    expect(find.text("Discography"), findsOneWidget);
    // empty sections are hidden
    expect(find.text("Empty"), findsNothing);
    // popular tracks are numbered
    expect(find.text("1"), findsOneWidget);
    expect(find.text("2"), findsOneWidget);
  });

  testWidgets("J moves the selection across sections", (tester) async {
    await pumpHost(tester);
    host.show(artistView());
    await tester.pumpAndSettle();

    bool isSelected(String name) => tester
        .widget<ListTile>(
          find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
        )
        .selected;

    expect(isSelected("a"), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pumpAndSettle();
    expect(isSelected("a"), isFalse);
    expect(isSelected("c"), isTrue);
  });

  testWidgets("Shift+A replaces the popup with the owner's profile", (
    tester,
  ) async {
    await pumpHost(tester);
    host.show(artistView());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: "A");
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    // the artist page is gone; the user profile tried to load (no network in
    // tests) and B returns straight to the base page
    expect(find.text("Joy Division"), findsNothing);
    expect(find.textContaining("user profile"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.pumpAndSettle();
    expect(host.isOpen, isFalse);
    expect(find.text("base"), findsOneWidget);
  });

  testWidgets("items without an artist/owner don't open anything", (
    tester,
  ) async {
    await pumpHost(tester);
    final context = tester.element(find.text("base"));
    openCreatorPage(context, item("x"));
    await tester.pumpAndSettle();
    expect(host.isOpen, isFalse);
  });
}
