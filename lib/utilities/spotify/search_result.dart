import 'package:lightify/utilities/spotify/search_item.dart';

class SearchResult {
  late List<SearchItem> tracks;
  late List<SearchItem> albums;
  late List<SearchItem> playlists;
  
  SearchResult() {
    tracks = List.empty(growable: true);
    albums = List.empty(growable: true);
    playlists = List.empty(growable: true);
  }
}
