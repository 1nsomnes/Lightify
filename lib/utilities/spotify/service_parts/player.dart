part of '../spotify_service.dart';

extension Player on SpotifyService {
  Future<Response> playPlaylistOrAlbums(String uri, {String deviceId = ""}) {
    return dio.put(
      "me/player/play",
      queryParameters: {if (deviceId.isNotEmpty) "device_id": deviceId},
      data: {"context_uri": uri},
    );
  }

  Future<Response> setShuffleMode(
    ShuffleState shuffleState, {
    String deviceId = "",
  }) {
    return dio.put(
      "me/player/shuffle",
      queryParameters: {
        "state": shuffleState.value,
        if (deviceId.isNotEmpty) "device_id": deviceId,
      },
    );
  }

  Future<Response> setRepeatMode(
    RepeatState repeatState, {
    String deviceId = "",
  }) {
    return dio.put(
      "me/player/repeat",
      queryParameters: {
        "state": repeatState.value,
        if (deviceId.isNotEmpty) "device_id": deviceId,
      },
    );
  }

  Future<Response> getPlaybackState({notifyListeners = true}) async {
    final response = await dio.get("me/player");

    if (response.statusCode == 200 && notifyListeners) {
      final json = response.data;

      _playbackStateCtrl.add(
        PlaybackState(
          playing: json["is_playing"] == true,
          shuffleState: json["shuffle_state"] == true
              ? ShuffleState.shuffleOn
              : ShuffleState.shuffleOff,
          repeatState: switch (json["repeat_state"]) {
            "off" => RepeatState.repeatOff,
            "context" => RepeatState.repeatContext,
            _ => RepeatState.repeatOne,
          },
        ),
      );
    }

    return response;
  }

  void processStateFromPlayer(Map<String, dynamic> json) {
    _playbackStateCtrl.add(
      PlaybackState(
        playing: json["paused"] == false,
        shuffleState: json["shuffle_mode"] == 1
            ? ShuffleState.shuffleOn
            : ShuffleState.shuffleOff,
        repeatState: switch (json["repeat_mode"]) {
          0 => RepeatState.repeatOff,
          1 => RepeatState.repeatContext,
          _ => RepeatState.repeatOne,
        },
      ),
    );
  }

  Future<Response> getLikedPlaylists(int limit, int offset) {
    return dio.get(
      "me/playlists",
      queryParameters: {"limit": limit.toString(), "offset": offset.toString()},
    );
  }

  Future<Response> getLikedSongs(int limit, int offset) {
    return dio.get(
      "me/tracks",
      queryParameters: {"limit": limit.toString(), "offset": offset.toString()},
    );
  }

  Future<Response> getLikedAlbums(int limit, int offset) {
    return dio.get(
      "me/albums",
      queryParameters: {"limit": limit.toString(), "offset": offset.toString()},
    );
  }

  // Tracks are played as a list of uris, albums/playlists as a context
  Future<Response> playUri(String uri, {String deviceId = ""}) {
    return uri.split(":").elementAtOrNull(1) == "track"
        ? playTracks([uri], deviceId: deviceId)
        : playPlaylistOrAlbums(uri, deviceId: deviceId);
  }

  // Starts [contextUri] (an album or playlist) at [trackUri]
  Future<Response> playInContext(
    String contextUri,
    String trackUri, {
    String deviceId = "",
  }) {
    return dio.put(
      "me/player/play",
      queryParameters: {if (deviceId.isNotEmpty) "device_id": deviceId},
      data: {
        "context_uri": contextUri,
        "offset": {"uri": trackUri},
      },
    );
  }

  // Spotify only queues single tracks/episodes, not albums or playlists
  Future<void> queueIfPlayable(String uri, {String deviceId = ""}) async {
    final kind = uri.split(":").elementAtOrNull(1);
    if (kind != "track" && kind != "episode") {
      debugPrint("can't queue a $kind, only tracks and episodes");
      return;
    }
    try {
      await queue(uri, deviceId: deviceId);
    } on DioException catch (e) {
      debugPrint("queueing $uri failed: $e");
    }
  }

  Future<Response> getQueue() {
    return dio.get("me/player/queue");
  }

  Future<Response> queue(String uri, {String deviceId = ""}) {
    return dio.post(
      "me/player/queue",
      queryParameters: {
        "uri": uri,
        if (deviceId.isNotEmpty) "device_id": deviceId,
      },
    );
  }

  Future<Response> searchSpotify(String query, int limit, int offset) {
    return dio.get(
      "search",
      queryParameters: {
        'q': query,
        'type': 'track,album,playlist',
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<Response> playTracks(List<String> uris, {String deviceId = ""}) {
    return dio.put(
      "me/player/play",
      queryParameters: {if (deviceId.isNotEmpty) "device_id": deviceId},
      data: {"uris": uris},
    );
  }

  Future<Response> transferPlayback() {
    return dio.put(
      "/me/player",
      data: {
        "device_ids": [_deviceId],
      },
    );
  }
}
