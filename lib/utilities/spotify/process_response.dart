import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/search_result.dart';

class ProcessResponse {
  // Spotify orders images largest first; some items (e.g. local files) have none
  static String smallestImageUrl(dynamic images) {
    if (images is! List || images.isEmpty) return "";
    return images.last["url"] ?? "";
  }

  static SearchResult parseSearchResults(dynamic json) {
    SearchResult result = SearchResult();

    processTracksJson(json["tracks"]["items"], result.tracks);
    processAlbumsJson(json["albums"]["items"], result.albums);
    processPlaylistsJson(json["playlists"]["items"], result.playlists);

    return result;
  }

  static void processTracksJson(
    List<dynamic> data,
    List<dynamic> list, {
    bool savedResult = false,
  }) {
    for (dynamic track in data) {
      if (savedResult) track = track["track"];
      list.add(_artistItem(track, track["album"]?["images"]));
    }
  }

  static void processAlbumsJson(
    List<dynamic> data,
    List<dynamic> list, {
    bool savedResult = false,
  }) {
    for (dynamic album in data) {
      if (savedResult) album = album["album"];
      list.add(_artistItem(album, album["images"]));
    }
  }

  static void processPlaylistsJson(
    List<dynamic> data,
    List<dynamic> list, {
    bool savedResult = false,
  }) {
    for (dynamic playlist in data) {
      if (playlist == null) continue;
      list.add(
        SearchItem(
          name: playlist["name"] ?? "",
          artist: playlist["owner"]["display_name"] ?? "",
          imgUrl: smallestImageUrl(playlist["images"]),
          ctxUri: playlist["uri"] ?? "",
          creatorUri: playlist["owner"]?["uri"],
        ),
      );
    }
  }

  // Queue entries are tracks or podcast episodes; episodes have a show
  // instead of artists and their own images instead of an album
  static SearchItem queueItem(dynamic item) {
    final isEpisode = item["type"] == "episode";
    return SearchItem(
      name: item["name"] ?? "",
      artist: isEpisode
          ? (item["show"]?["name"] ?? "")
          : _joinArtistNames(item["artists"] ?? []),
      imgUrl: smallestImageUrl(
        isEpisode ? item["images"] : item["album"]?["images"],
      ),
      ctxUri: item["uri"] ?? "",
      creatorUri: isEpisode ? null : firstArtistUri(item["artists"]),
    );
  }

  // Shared by tracks and albums: both carry name/uri and an "artists" list
  static SearchItem _artistItem(dynamic json, dynamic images) {
    return SearchItem(
      name: json["name"],
      artist: _joinArtistNames(json["artists"]),
      imgUrl: smallestImageUrl(images),
      ctxUri: json["uri"],
      creatorUri: firstArtistUri(json["artists"]),
    );
  }

  static String? firstArtistUri(dynamic artists) {
    if (artists is! List || artists.isEmpty) return null;
    return artists.first["uri"];
  }

  // Builds "A, B, C" directly instead of via a mapped iterable + dynamic join
  static String _joinArtistNames(List<dynamic> artists) {
    final buffer = StringBuffer();
    for (int i = 0; i < artists.length; i++) {
      if (i > 0) buffer.write(', ');
      buffer.write(artists[i]['name'] as String);
    }
    return buffer.toString();
  }
}
