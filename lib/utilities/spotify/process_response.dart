import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_result.dart';

class ProcessResponse {
  // Spotify orders images largest first; some items (e.g. local files) have none
  static String smallestImageUrl(dynamic images) {
    if (images is! List || images.isEmpty) return "";
    return images.last["url"] ?? "";
  }

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
        imgUrl: smallestImageUrl(track["album"]?["images"]),
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
        imgUrl: smallestImageUrl(album["images"]),
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
        imgUrl: smallestImageUrl(playlist["images"]),
        ctxUri: playlist["uri"] ?? "",
      );
      list.add(item);
    }
  }

}
