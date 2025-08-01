import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_result.dart';

class ProcessResponse {
  static SearchResult parseSearchResults(dynamic json) {

    List<dynamic> tracks = json["tracks"]["items"];
    List<dynamic> albums = json["albums"]["items"];
    List<dynamic> playlists = json["playlists"]["items"];

    SearchResult result = SearchResult(); 
    
    processTracksJson(tracks, result.tracks);
    processAlbumsJson(albums, result.albums);
    processPlaylistsJson(playlists, result.playlists);


    return result;
  }
  
  static processTracksJson(List<dynamic> data, List<dynamic> list, { bool savedResult = false}) {
    for (dynamic track in data) {
      if(savedResult) track = track["track"];
      var item = SearchItem(
        name: track["name"],
        artist: track["artists"].map((i) => i['name'] as String).join(', '),
        imgUrl: track["album"]["images"][2]["url"],
        ctxUri: track["uri"],
      );
      list.add(item);
    }
  }

  static processAlbumsJson(List<dynamic> data, List<dynamic> list, { bool savedResult = false}) {
    for (dynamic album in data) {
      if(savedResult) album = album["album"];
      var item = SearchItem(
        name: album["name"],
        artist: album["artists"].map((i) => i['name'] as String).join(', '),
        imgUrl: album["images"][2]["url"],
        ctxUri: album["uri"],
      );
      list.add(item);
    }
  }

  static processPlaylistsJson(List<dynamic> data, List<dynamic> list, { bool savedResult = false}) {
    for (dynamic playlist in data) {
      //debugPrint(playlist.toString());
      if(playlist == null) continue;
      var item = SearchItem(
        name: playlist["name"] ?? "",
        artist: playlist["owner"]["display_name"] ?? "",
        imgUrl: playlist["images"][0]["url"] ?? "",
        ctxUri: playlist["uri"] ?? "",
      );
      list.add(item);
    }
  }

}
