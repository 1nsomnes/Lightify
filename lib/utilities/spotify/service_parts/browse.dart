part of '../spotify_service.dart';

// Read-only lookups used by the artist and user profile pages
extension Browse on SpotifyService {
  Future<Response> getArtist(String id) {
    return dio.get("artists/${Uri.encodeComponent(id)}");
  }

  Future<Response> getArtistTopTracks(String id) {
    return dio.get("artists/${Uri.encodeComponent(id)}/top-tracks");
  }

  Future<Response> getArtistAlbums(String id) {
    return dio.get(
      "artists/${Uri.encodeComponent(id)}/albums",
      queryParameters: {"include_groups": "album,single"},
    );
  }

  Future<Response> getAlbum(String id) {
    return dio.get("albums/${Uri.encodeComponent(id)}");
  }

  Future<Response> getUser(String id) {
    return dio.get("users/${Uri.encodeComponent(id)}");
  }

  Future<Response> getUserPlaylists(String id) {
    return dio.get("users/${Uri.encodeComponent(id)}/playlists");
  }
}
