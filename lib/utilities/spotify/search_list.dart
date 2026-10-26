import 'package:lightify/utilities/spotify/search_item.dart';

class SearchList {
  List<SearchItem> items;
  int selected;

  SearchList({List<SearchItem>? items, this.selected = 0})
    : items = items ?? <SearchItem>[];

  /// Combines per-kind result lists into one. [interleave] alternates them by
  /// rank (each list's best match first), which suits search results;
  /// otherwise they're joined one after another.
  static List<SearchItem> merge(
    List<List<SearchItem>> lists, {
    bool interleave = true,
  }) {
    if (!interleave) return [for (final list in lists) ...list];
    final merged = <SearchItem>[];
    final longest = lists.fold(0, (n, l) => l.length > n ? l.length : n);
    for (int i = 0; i < longest; i++) {
      for (final list in lists) {
        if (i < list.length) merged.add(list[i]);
      }
    }
    return merged;
  }
}
