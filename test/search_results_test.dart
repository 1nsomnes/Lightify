import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/components/item_tile.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_list.dart';

SearchItem item(String kind, String id) =>
    SearchItem(name: id, artist: "", imgUrl: "", ctxUri: "spotify:$kind:$id");

void main() {
  final tracks = [
    item("track", "t1"),
    item("track", "t2"),
    item("track", "t3"),
  ];
  final albums = [item("album", "a1")];
  final playlists = [item("playlist", "p1"), item("playlist", "p2")];

  List<String> names(List<SearchItem> items) => [for (final i in items) i.name];

  test("search results interleave by rank", () {
    expect(names(SearchList.merge([tracks, albums, playlists])), [
      "t1",
      "a1",
      "p1",
      "t2",
      "p2",
      "t3",
    ]);
  });

  test("a library listing is grouped by kind", () {
    expect(names(SearchList.merge([tracks, playlists], interleave: false)), [
      "t1",
      "t2",
      "t3",
      "p1",
      "p2",
    ]);
  });

  testWidgets("search rows show a T / A / P badge", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              for (final i in [tracks[0], albums[0], playlists[0]])
                ItemTile(item: i, selected: false, showKind: true),
              ItemTile(item: tracks[1], selected: false),
            ],
          ),
        ),
      ),
    );
    expect(find.text("T"), findsOneWidget);
    expect(find.text("A"), findsOneWidget);
    expect(find.text("P"), findsOneWidget);
  });
}
