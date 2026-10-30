import 'package:flutter/foundation.dart';
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_list.dart';

enum SearchKind { track, album, playlist }

/// Fetches one page of search results for [kinds], starting at [offset];
/// returns Spotify's search response (`{"tracks": {...}, "albums": ...}`).
typedef SearchFetch =
    Future<dynamic> Function(String query, List<SearchKind> kinds, int offset);

/// Spotify search results, loaded a page at a time. Spotify allows at most
/// [pageSize] results per kind per request, so [start] loads the first page
/// and [loadMore] the next one (the search list calls it as the selection
/// nears the bottom).
class SearchPager {
  SearchPager({required this.fetch, required this.onChanged});

  static const pageSize = 10;

  final SearchFetch fetch;
  // called after results were added (the widget rebuilds)
  final VoidCallback onChanged;

  final Map<SearchKind, SearchList> lists = {
    for (final kind in SearchKind.values) kind: SearchList(),
  };

  final Map<SearchKind, int> _nextOffset = {
    for (final kind in SearchKind.values) kind: 0,
  };
  // kinds with no more results for this query
  final Set<SearchKind> _ended = {};
  String _query = "";
  // bumped by every new search, so responses for an older one are dropped
  int _generation = 0;
  bool _loading = false;

  bool get isLoading => _loading;

  bool hasMore(SearchKind kind) => _query.isNotEmpty && !_ended.contains(kind);

  /// Clears the results and loads the first page of [query] for [kinds]
  /// (nothing for an empty query).
  void start(String query, Set<SearchKind> kinds) {
    _generation++;
    _query = query;
    _loading = false;
    _ended.clear();
    for (final kind in SearchKind.values) {
      lists[kind]!.items = [];
      lists[kind]!.selected = 0;
      _nextOffset[kind] = 0;
    }
    if (query.isNotEmpty) loadMore(kinds);
  }

  /// Loads the next page of [kinds], unless a page is already loading. Kinds
  /// that were turned on later (and are a page or more behind) catch up
  /// first.
  Future<void> loadMore(Set<SearchKind> kinds) async {
    if (_loading || _query.isEmpty) return;
    final wanted = [
      for (final kind in SearchKind.values)
        if (kinds.contains(kind) && !_ended.contains(kind)) kind,
    ];
    if (wanted.isEmpty) return;
    // one request per offset: the kinds that are furthest behind go together
    final offset = wanted
        .map((kind) => _nextOffset[kind]!)
        .reduce((a, b) => a < b ? a : b);
    final batch = [
      for (final kind in wanted)
        if (_nextOffset[kind] == offset) kind,
    ];

    final generation = _generation;
    _loading = true;
    var loaded = false;
    try {
      final data = await fetch(_query, batch, offset);
      if (generation != _generation) return;
      for (final kind in batch) {
        _addPage(kind, data?[_responseKey(kind)], offset);
      }
      loaded = true;
      onChanged();
    } catch (e) {
      // left as is, so the next trigger retries
      debugPrint("couldn't load more search results: $e");
    } finally {
      if (generation == _generation) _loading = false;
    }

    // a kind turned on while this page loaded still needs its first page
    if (loaded &&
        generation == _generation &&
        kinds.any((k) => _nextOffset[k] == 0 && !_ended.contains(k))) {
      await loadMore(kinds);
    }
  }

  void _addPage(SearchKind kind, dynamic page, int offset) {
    if (page == null) {
      _ended.add(kind);
      return;
    }
    final parsed = <SearchItem>[];
    final items = (page["items"] as List?) ?? [];
    switch (kind) {
      case SearchKind.track:
        ProcessResponse.processTracksJson(items, parsed);
      case SearchKind.album:
        ProcessResponse.processAlbumsJson(items, parsed);
      case SearchKind.playlist:
        ProcessResponse.processPlaylistsJson(items, parsed);
    }
    // later pages can repeat an earlier result
    final list = lists[kind]!;
    final seen = {for (final item in list.items) item.ctxUri};
    list.items = [
      ...list.items,
      for (final item in parsed)
        if (seen.add(item.ctxUri)) item,
    ];
    _nextOffset[kind] = offset + pageSize;
    if (page["next"] == null || items.isEmpty) _ended.add(kind);
  }

  static String _responseKey(SearchKind kind) => switch (kind) {
    SearchKind.track => "tracks",
    SearchKind.album => "albums",
    SearchKind.playlist => "playlists",
  };

  /// The `type` parameter of Spotify's search for [kinds].
  static String typeParameter(List<SearchKind> kinds) =>
      kinds.map((kind) => kind.name).join(",");
}
