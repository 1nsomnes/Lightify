import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/components/popup_host.dart';
import 'package:lightify/components/profile_view.dart';
import 'package:lightify/utilities/spotify/process_response.dart';
import 'package:lightify/utilities/spotify/search_item.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';

/// Opens the artist page (tracks/albums) or user profile (playlists) for
/// [item], replacing any open popup.
void openCreatorPage(BuildContext context, SearchItem item) {
  final parts = item.creatorUri?.split(":");
  if (parts == null || parts.length < 3) {
    debugPrint("no artist or owner to open for ${item.ctxUri}");
    return;
  }
  final id = parts[2];
  final Widget? page = switch (parts[1]) {
    "artist" => ProfileView(
      kind: "Artist",
      icon: Icons.verified,
      load: () => _loadArtist(id),
    ),
    "user" => ProfileView(
      kind: "User profile",
      icon: Icons.person,
      load: () => _loadUser(id),
    ),
    _ => null,
  };
  if (page != null) PopupHost.of(context).show(page);
}

/// Opens the album page for [item]: an album itself, or a track's album.
void openAlbumPage(BuildContext context, SearchItem item) {
  final albumUri = item.ctxUri.split(":").elementAtOrNull(1) == "album"
      ? item.ctxUri
      : item.albumUri;
  final id = albumUri?.split(":").elementAtOrNull(2);
  if (albumUri == null || id == null) {
    debugPrint("no album to open for ${item.ctxUri}");
    return;
  }
  PopupHost.of(context).show(
    ProfileView(
      kind: "Album",
      icon: Icons.album,
      roundArtwork: false,
      load: () => _loadAlbum(id),
    ),
  );
}

Future<ProfileData> _loadArtist(String id) async {
  final spotify = GetIt.instance.get<SpotifyService>();
  // the artist itself is required; the lists are shown when available
  final results = await Future.wait([
    spotify.getArtist(id),
    _orNull(spotify.getArtistTopTracks(id)),
    _orNull(spotify.getArtistAlbums(id)),
  ]);
  final artist = results[0]!.data;
  final List<dynamic> tracks = results[1]?.data["tracks"] ?? [];
  final List<dynamic> albums = results[2]?.data["items"] ?? [];

  final genres = (artist["genres"] as List?)?.take(2).join(", ") ?? "";
  final String name = artist["name"] ?? "";
  return ProfileData(
    name: name,
    imageUrl: _largestImageUrl(artist["images"]),
    details: [
      _followers(artist["followers"]?["total"]),
      genres,
    ].where((s) => s.isNotEmpty).join("  ·  "),
    sections: [
      // plays the artist itself as a context (Enter goes through playUri),
      // which Spotify continues with autoplay
      ProfileSection(
        title: "",
        icon: Icons.radio,
        items: [
          SearchItem(
            name: "Artist radio",
            artist: "Songs by $name, then similar music",
            imgUrl: "",
            ctxUri: artist["uri"] ?? "spotify:artist:$id",
          ),
        ],
      ),
      ProfileSection(
        title: "Popular",
        numbered: true,
        // a song plays with the rest of the list after it, then autoplay
        playsFollowing: true,
        items: [
          for (final track in tracks.take(10))
            SearchItem(
              name: track["name"] ?? "",
              artist: track["album"]?["name"] ?? "",
              imgUrl: ProcessResponse.smallestImageUrl(
                track["album"]?["images"],
              ),
              ctxUri: track["uri"] ?? "",
              creatorUri: ProcessResponse.firstArtistUri(track["artists"]),
              albumUri: track["album"]?["uri"],
            ),
        ],
      ),
      ProfileSection(
        title: "Discography",
        items: [
          for (final album in albums)
            SearchItem(
              name: album["name"] ?? "",
              artist: _albumSubtitle(album),
              imgUrl: ProcessResponse.smallestImageUrl(album["images"]),
              ctxUri: album["uri"] ?? "",
              creatorUri: ProcessResponse.firstArtistUri(album["artists"]),
            ),
        ],
      ),
    ],
  );
}

Future<ProfileData> _loadUser(String id) async {
  final spotify = GetIt.instance.get<SpotifyService>();
  final results = await Future.wait([
    spotify.getUser(id),
    _orNull(spotify.getUserPlaylists(id)),
  ]);
  final user = results[0]!.data;
  final List<dynamic> playlists = results[1]?.data["items"] ?? [];

  return ProfileData(
    name: user["display_name"] ?? id,
    imageUrl: _largestImageUrl(user["images"]),
    details: _followers(user["followers"]?["total"]),
    sections: [
      ProfileSection(
        title: "Public playlists",
        items: [
          for (final playlist in playlists)
            if (playlist != null)
              SearchItem(
                name: playlist["name"] ?? "",
                artist: _trackCount(playlist),
                imgUrl: ProcessResponse.smallestImageUrl(playlist["images"]),
                ctxUri: playlist["uri"] ?? "",
                creatorUri: playlist["owner"]?["uri"],
              ),
        ],
      ),
    ],
  );
}

Future<ProfileData> _loadAlbum(String id) async {
  final album = (await GetIt.instance.get<SpotifyService>().getAlbum(id)).data;
  final String albumUri = album["uri"] ?? "spotify:album:$id";
  final List<dynamic> tracks = album["tracks"]?["items"] ?? [];

  final minutes =
      tracks.fold<int>(0, (sum, t) => sum + ((t["duration_ms"] ?? 0) as int)) ~/
      60000;
  final int count = album["total_tracks"] ?? tracks.length;
  return ProfileData(
    name: album["name"] ?? "",
    imageUrl: _largestImageUrl(album["images"]),
    details: [
      ProcessResponse.joinArtistNames(album["artists"] ?? []),
      _albumSubtitle(album),
      "$count ${count == 1 ? "song" : "songs"}, $minutes min",
    ].where((s) => s.isNotEmpty).join("  ·  "),
    sections: [
      ProfileSection(
        title: "Tracks",
        numbered: true,
        contextUri: albumUri,
        items: [
          // album tracks don't repeat the album, so link them back to it
          for (final track in tracks)
            SearchItem(
              name: track["name"] ?? "",
              artist: ProcessResponse.joinArtistNames(track["artists"] ?? []),
              imgUrl: ProcessResponse.smallestImageUrl(album["images"]),
              ctxUri: track["uri"] ?? "",
              creatorUri: ProcessResponse.firstArtistUri(track["artists"]),
              albumUri: albumUri,
            ),
        ],
      ),
    ],
  );
}

Future<Response?> _orNull(Future<Response> request) async {
  try {
    return await request;
  } on DioException catch (e) {
    debugPrint("optional profile request failed: $e");
    return null;
  }
}

String _largestImageUrl(dynamic images) {
  if (images is! List || images.isEmpty) return "";
  return images.first["url"] ?? "";
}

String _followers(dynamic total) {
  if (total is! int) return "";
  final digits = total.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(",");
    buffer.write(digits[i]);
  }
  return "$buffer ${total == 1 ? "follower" : "followers"}";
}

// e.g. "2007 · Album"
String _albumSubtitle(dynamic album) {
  final String date = album["release_date"] ?? "";
  final String type = album["album_type"] ?? "";
  return [
    if (date.length >= 4) date.substring(0, 4),
    if (type.isNotEmpty) type[0].toUpperCase() + type.substring(1),
  ].join(" · ");
}

String _trackCount(dynamic playlist) {
  final total = playlist["tracks"]?["total"] ?? playlist["items"]?["total"];
  return total is int
      ? "$total ${total == 1 ? "track" : "tracks"}"
      : "Playlist";
}
