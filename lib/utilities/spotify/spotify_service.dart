import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/providers/auth_provider.dart';
import "package:http/http.dart" as http;

class SpotifyService {
  final FlutterSecureStorage _storage;
  final AuthProvider _authProvider;

  SpotifyService({
    required FlutterSecureStorage storage,
    required AuthProvider authProvider,
  }) : _storage = storage,
       _authProvider = authProvider;

  Future<http.Response> searchSpotify(
    String query,
    int limit,
    int offset,
  ) async {
    final token = _authProvider.getToken;
    final url = Uri.parse("https://api.spotify.com/v1/search").replace(
      queryParameters: {
        "q": query,
        "type": "track,album,playlist",
        "limit": limit.toString(),
        "offset": offset.toString(),
      },
    );

    final response = await http.get(
      url,

      headers: {'Authorization': 'Bearer $token'},
    );

    return response;
  }

  Future<http.Response> getPlaybackState() async {
    final token = _authProvider.getToken;
    final uri = Uri.parse('https://api.spotify.com/v1/me/player');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response;
  }

  Future<http.Response> playTracks(
    List<String> uris, {
    String deviceId = "",
  }) async {
    final token = _authProvider.getToken;

    Uri url = Uri.parse("https://api.spotify.com/v1/me/player/play");
    if (deviceId.isNotEmpty) {
      url = url.replace(queryParameters: {"device_id": deviceId});
    }

    final Map<String, dynamic> payload = {"uris": uris};

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    //debugPrint(response.body.toString());

    return response;
  }

  Future<http.Response> playPlaylistOrAlbums(
    String uri, {
    String deviceId = "",
  }) async {
    final token = _authProvider.getToken;
    Uri url = Uri.parse("https://api.spotify.com/v1/me/player/play");
    if (deviceId.isNotEmpty) {
      url = url.replace(queryParameters: {"device_id": deviceId});
    }

    final Map<String, dynamic> payload = {"context_uri": uri};

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    //debugPrint(response.body.toString());

    return response;
  }

  Future<http.Response> getPlaybackStateByToken() async {
    final token = _authProvider.getToken;
    final uri = Uri.parse('https://api.spotify.com/v1/me/player');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    return response;
  }

  Future<http.Response> getLikedPlaylists(int limit, int offset) async {
    final token = _authProvider.getToken;
    final url = Uri.parse("https://api.spotify.com/v1/me/playlists").replace(
      queryParameters: {"limit": limit.toString(), "offset": offset.toString()},
    );

    final response = await http.get(
      url,

      headers: {'Authorization': 'Bearer $token'},
    );

    return response;
  }

  Future<http.Response> queue(String uri, {String deviceId = ""}) async {
    final token = _authProvider.getToken;
    Uri url = Uri.parse("https://api.spotify.com/v1/me/player/queue");
    if (deviceId.isNotEmpty) {
      url = url.replace(queryParameters: {"uri": uri, "device_id": deviceId});
    } else {
      url = url.replace(queryParameters: {"uri": uri});
    }

    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    //debugPrint(response.body.toString());

    return response;
  }
}
