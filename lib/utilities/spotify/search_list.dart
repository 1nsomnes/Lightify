import 'package:lightify/utilities/spotify/search_item.dart';


class SearchList {
  List<SearchItem> items;
  int selected;

  SearchList({
    List<SearchItem>? items,
    this.selected = 0,
  }) : items = items ?? <SearchItem>[];
}
