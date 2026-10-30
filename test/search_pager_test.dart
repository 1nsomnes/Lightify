import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightify/utilities/spotify/search_pager.dart';

// a page of [count] tracks / albums starting at [offset]; [more] says whether
// Spotify has a next page
Map<String, dynamic> page(
  String type,
  int offset,
  int count, {
  bool more = true,
}) => {
  "items": [
    for (var i = offset; i < offset + count; i++)
      {
        "name": "$type$i",
        "uri": "spotify:$type:$i",
        "artists": [
          {"name": "artist", "uri": "spotify:artist:x"},
        ],
        "images": [],
        "album": {"images": [], "uri": "spotify:album:x"},
      },
  ],
  "next": more ? "next" : null,
};

void main() {
  late List<(String, List<SearchKind>, int)> calls;
  late Map<String, Completer<dynamic>> pending;
  late SearchPager pager;
  late int changes;

  setUp(() {
    calls = [];
    pending = {};
    changes = 0;
    pager = SearchPager(
      fetch: (query, kinds, offset) {
        calls.add((query, kinds, offset));
        final completer = Completer<dynamic>();
        pending["$query@$offset"] = completer;
        return completer.future;
      },
      onChanged: () => changes++,
    );
  });

  List<String> names(SearchKind kind) => [
    for (final item in pager.lists[kind]!.items) item.name,
  ];

  test("loads 10 per kind, then the next page on request", () async {
    final kinds = {SearchKind.track, SearchKind.album};
    pager.start("song", kinds);
    expect(calls.single.$1, "song");
    expect(calls.single.$2, [SearchKind.track, SearchKind.album]);
    expect(calls.single.$3, 0);
    expect(SearchPager.typeParameter(calls.single.$2), "track,album");

    pending["song@0"]!.complete({
      "tracks": page("track", 0, 10),
      "albums": page("album", 0, 10),
    });
    await pumpEventQueue();
    expect(names(SearchKind.track), [for (var i = 0; i < 10; i++) "track$i"]);
    expect(changes, 1);

    pager.loadMore(kinds);
    expect(calls.last.$3, 10);
    // only one page at a time
    pager.loadMore(kinds);
    expect(calls.length, 2);

    pending["song@10"]!.complete({
      "tracks": page("track", 10, 10, more: false),
      "albums": page("album", 10, 10),
    });
    await pumpEventQueue();
    expect(pager.lists[SearchKind.track]!.items.length, 20);
    expect(pager.hasMore(SearchKind.track), isFalse);

    // tracks ran out, so only albums are asked for
    pager.loadMore(kinds);
    expect(calls.last.$2, [SearchKind.album]);
    expect(calls.last.$3, 20);
  });

  test("results for an older query are dropped", () async {
    pager.start("old", {SearchKind.track});
    pager.start("new", {SearchKind.track});
    pending["old@0"]!.complete({"tracks": page("track", 0, 10)});
    await pumpEventQueue();
    expect(pager.lists[SearchKind.track]!.items, isEmpty);

    pending["new@0"]!.complete({"tracks": page("track", 0, 3, more: false)});
    await pumpEventQueue();
    expect(pager.lists[SearchKind.track]!.items.length, 3);
  });

  test(
    "a kind turned on later gets its first page before more of the others",
    () async {
      final kinds = {SearchKind.track};
      pager.start("q", kinds);
      pending["q@0"]!.complete({"tracks": page("track", 0, 10)});
      await pumpEventQueue();

      kinds.add(SearchKind.album);
      pager.loadMore(kinds);
      expect(calls.last.$2, [SearchKind.album]);
    expect(calls.last.$3, 0);
    },
  );

  test("repeated results across pages are shown once", () async {
    pager.start("q", {SearchKind.track});
    pending["q@0"]!.complete({"tracks": page("track", 0, 10)});
    await pumpEventQueue();
    pager.loadMore({SearchKind.track});
    pending["q@10"]!.complete({"tracks": page("track", 8, 10)});
    await pumpEventQueue();
    expect(pager.lists[SearchKind.track]!.items.length, 18);
  });

  test("a failed page can be retried", () async {
    pager.start("q", {SearchKind.track});
    pending["q@0"]!.completeError(Exception("offline"));
    await pumpEventQueue();
    expect(pager.isLoading, isFalse);
    pager.loadMore({SearchKind.track});
    expect(calls.length, 2);
    expect(calls.last.$3, 0);
  });
}
