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

  // Starts [contextUri] (an album, playlist, artist...) at [trackUri], or at
  // its beginning when [trackUri] is null
  Future<Response> playInContext(
    String contextUri,
    String? trackUri, {
    String deviceId = "",
  }) {
    return dio.put(
      "me/player/play",
      queryParameters: {if (deviceId.isNotEmpty) "device_id": deviceId},
      data: {
        "context_uri": contextUri,
        if (trackUri != null) "offset": {"uri": trackUri},
      },
    );
  }

  // Plays tracks[index] as part of [contextUri] (an album, playlist or the
  // liked songs), the way Spotify does: the rest of the context plays next,
  // then Spotify's autoplay takes over. If Spotify refuses, the songs from
  // [index] on are played as a list instead.
  Future<void> playTrackInContext(
    String contextUri,
    List<String> tracks,
    int index, {
    String deviceId = "",
  }) async {
    try {
      await playInContext(contextUri, tracks[index], deviceId: deviceId);
    } on DioException catch (e) {
      debugPrint("playing in $contextUri failed: $e");
      await playTracksFrom(tracks, index, deviceId: deviceId);
    }
  }

  // Plays tracks[index] followed by the rest of [tracks]; Spotify's autoplay
  // continues after the last one
  Future<void> playTracksFrom(
    List<String> tracks,
    int index, {
    String deviceId = "",
  }) async {
    try {
      // the request limits how many songs can be sent
      await playTracks(
        tracks.skip(index).take(100).toList(),
        deviceId: deviceId,
      );
    } on DioException catch (e) {
      debugPrint("playing ${tracks[index]} failed: $e");
    }
  }

  // The "Liked Songs" playlist
  Future<String> likedSongsUri() async =>
      "spotify:user:${await getCurrentUserId()}:collection";

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

  // The web player can re-register under a new id (e.g. after the Mac sleeps)
  // without firing `ready` again, so look it up by name. Returns true when the
  // id changed.
  Future<bool> refreshDeviceId() async {
    try {
      final response = await dio.get("me/player/devices");
      final devices = (response.data["devices"] as List)
          .where(
            (d) => d["name"] == SpotifyService.playerName && d["id"] != null,
          )
          .toList();
      if (devices.isEmpty) return false;
      // two Macs running Lightify both show up; the active one is ours
      final device = devices.firstWhere(
        (d) => d["is_active"] == true,
        orElse: () => devices.first,
      );
      final String id = device["id"];
      if (id == _deviceId) return false;
      debugPrint("device id changed: $_deviceId -> $id");
      _deviceId = id;
      return true;
    } on DioException catch (e) {
      debugPrint("couldn't look up the device id: $e");
      return false;
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

  /// Moves playback from whatever device is playing to this one, keeping the
  /// track, position and queue.
  Future<void> transferPlayback() async {
    // the id is in the body, so the interceptor's stale-id retry can't help
    await refreshDeviceId();
    try {
      await dio.put(
        "me/player",
        data: {
          "device_ids": [_deviceId],
        },
      );
    } on DioException catch (e) {
      debugPrint("couldn't transfer playback: $e");
    }
  }
}
