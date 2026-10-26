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

    test("tracks link to their album", () {
      final list = <SearchItem>[];
      ProcessResponse.processTracksJson([
        {
          "name": "Atmosphere",
          "uri": "spotify:track:1",
          "album": {"uri": "spotify:album:closer", "images": []},
          "artists": [],
        },
      ], list);
      expect(list.single.albumUri, "spotify:album:closer");
      expect(list.single.creatorUri, isNull);
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
          items: [
            item("a"),
            item("b", creator: "spotify:user:someone"),
          ],
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

  testWidgets("an untitled icon section (artist radio) comes first", (
    tester,
  ) async {
    await pumpHost(tester);
    host.show(
      ProfileView(
        kind: "Artist",
        icon: Icons.verified,
        load: () async => ProfileData(
          name: "Joy Division",
          imageUrl: "",
          details: "",
          sections: [
            ProfileSection(
              title: "",
              icon: Icons.radio,
              items: [item("Artist radio")],
            ),
            ProfileSection(title: "Popular", items: [item("a")]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.radio), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text("Artist radio"),
              matching: find.byType(ListTile),
            ),
          )
          .selected,
      isTrue,
    );
    // no heading row for the untitled section, so radio sits above Popular
    expect(
      tester.getTopLeft(find.text("Artist radio")).dy,
      lessThan(tester.getTopLeft(find.text("Popular")).dy),
    );
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

  testWidgets("Shift+P replaces the popup with the owner's profile", (
    tester,
  ) async {
    await pumpHost(tester);
    host.show(artistView());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP, character: "P");
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    // the artist page is gone; the user profile tried to load (no network in
    // tests) and Esc returns straight to the base page
    expect(find.text("Joy Division"), findsNothing);
    expect(find.textContaining("user profile"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
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

  testWidgets("Shift+A opens a track's album, an album opens itself", (
    tester,
  ) async {
    await pumpHost(tester);
    final context = tester.element(find.text("base"));

    openAlbumPage(
      context,
      const SearchItem(
        name: "t",
        artist: "",
        imgUrl: "",
        ctxUri: "spotify:track:t",
        albumUri: "spotify:album:closer",
      ),
    );
    await tester.pumpAndSettle();
    // no network in tests, so the album page shows its load error
    expect(find.textContaining("Couldn't load this album"), findsOneWidget);

    host.close();
    await tester.pumpAndSettle();
    openAlbumPage(
      context,
      const SearchItem(
        name: "a",
        artist: "",
        imgUrl: "",
        ctxUri: "spotify:album:closer",
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't load this album"), findsOneWidget);

    // playlists have no album
    host.close();
    await tester.pumpAndSettle();
    openAlbumPage(
      context,
      const SearchItem(
        name: "p",
        artist: "",
        imgUrl: "",
        ctxUri: "spotify:playlist:p",
      ),
    );
    await tester.pumpAndSettle();
    expect(host.isOpen, isFalse);
  });

  testWidgets("Shift+O opens a playlist's page, or an album like Shift+A", (
    tester,
  ) async {
    await pumpHost(tester);
    final context = tester.element(find.text("base"));

    openCollectionPage(
      context,
      const SearchItem(
        name: "p",
        artist: "",
        imgUrl: "",
        ctxUri: "spotify:playlist:p",
      ),
    );
    await tester.pumpAndSettle();
    // no network in tests, so the playlist page shows its load error
    expect(find.textContaining("Couldn't load this playlist"), findsOneWidget);

    openCollectionPage(
      context,
      const SearchItem(
        name: "a",
        artist: "",
        imgUrl: "",
        ctxUri: "spotify:album:closer",
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't load this album"), findsOneWidget);

    // tracks open nothing, even with an album
    host.close();
    await tester.pumpAndSettle();
    openCollectionPage(
      context,
      const SearchItem(
        name: "t",
        artist: "",
        imgUrl: "",
        ctxUri: "spotify:track:t",
        albumUri: "spotify:album:closer",
      ),
    );
    await tester.pumpAndSettle();
    expect(host.isOpen, isFalse);
  });
}
