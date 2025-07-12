import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/providers/auth_provider.dart';
import "package:http/http.dart" as http;
import 'package:lightify/utilities/spotify/playback_state.dart';

class SpotifyService {
  final FlutterSecureStorage _storage;
  final AuthProvider _authProvider;

  final _playbackStateCtrl = StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get onPlaybackStateChanged => _playbackStateCtrl.stream;

  SpotifyService({
    required FlutterSecureStorage storage,
    required AuthProvider authProvider,
  }) : _storage = storage,
       _authProvider = authProvider;

  void dispose() {
    _playbackStateCtrl.close();
  }

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

  Future<http.Response> setShuffleMode(
    ShuffleState shuffleState, {
    String deviceId = "",
  }) async {
    final token = _authProvider.getToken;
    Uri url = Uri.parse(
      "https://api.spotify.com/v1/me/player/shuffle",
    );
    url = url.replace(queryParameters: {"state": shuffleState.value});
    if (deviceId.isNotEmpty) {
      url = url.replace(
        queryParameters: {"state": shuffleState.value, "device_id": deviceId},
      );
    }
    final response = await http.put(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint("response: ${response.body}");

    return response;
  }

  Future<http.Response> getPlaybackState({notifyListeners = true}) async {
    final token = _authProvider.getToken;
    final uri = Uri.parse('https://api.spotify.com/v1/me/player');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 && notifyListeners) {
      var json = jsonDecode(response.body);

      RepeatState repeatState = switch (json["repeat_state"]) {
        "off" => RepeatState.repeatOff,
        "context" => RepeatState.repeatContext,
        _ => RepeatState.repeatOne,
      };
      ShuffleState shuffleState = switch (json["shuffle_state"]) {
        true => ShuffleState.shuffleOn,
        _ => ShuffleState.shuffleOff,
      };

      bool isPlaying = json["is_playing"] == true ? true : false;

      PlaybackState playbackState = PlaybackState(
        playing: isPlaying,
        shuffleState: shuffleState,
        repeatState: repeatState,
      );

      _playbackStateCtrl.add(playbackState);
    }

    return response;
  }

  void processStateFromPlayer(Map<String, dynamic> json) {
    RepeatState repeatState = switch (json["repeat_mode"]) {
      0 => RepeatState.repeatOff,
      1 => RepeatState.repeatContext,
      _ => RepeatState.repeatOne,
    };
    ShuffleState shuffleState = switch (json["shuffle_mode"]) {
      1 => ShuffleState.shuffleOn,
      _ => ShuffleState.shuffleOff,
    };

    bool isPlaying = json["paused"] == false ? true : false;

    PlaybackState playbackState = PlaybackState(
      playing: isPlaying,
      shuffleState: shuffleState,
      repeatState: repeatState,
    );

    _playbackStateCtrl.add(playbackState);
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
