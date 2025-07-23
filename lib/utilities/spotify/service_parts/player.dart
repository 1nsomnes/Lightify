part of '../spotify_service.dart';

extension Player on SpotifyService {

  Future<Response> playPlaylistOrAlbums(
    String uri, {
    String deviceId = "",
  }) async {

    final Map<String, dynamic> payload = {"context_uri": uri};

    final response = await dio.put(
      "me/player/play",
      options: Options(headers: {
        "Content-Type" : "application/json"
      }),
      queryParameters: {
        if (deviceId.isNotEmpty) "device_id" : deviceId
      },
      data: jsonEncode(payload),
    );

    //debugPrint(response.body.toString());

    return response;
  }

  Future<Response> setShuffleMode(
    ShuffleState shuffleState, {
    String deviceId = "",
  }) async {

    final response = await dio.put(
      "me/player/shuffle",
      queryParameters: {
        "state" : shuffleState.value,
        if (deviceId.isNotEmpty) "device_id": deviceId
      }
    );

    //debugPrint("response: ${response.body}");

    return response;
  }

  Future<Response> setRepeatMode(
    RepeatState repeatState, {
    String deviceId = "",
  }) async {

    final response = await dio.put(
      "me/player/repeat",
      queryParameters: {
        "state": repeatState.value,
        if (deviceId.isNotEmpty) "device_id" : deviceId
      }
    );

    //debugPrint("response: ${response.body}");

    return response;
  }

  Future<Response> getPlaybackState({notifyListeners = true}) async {

    final response = await dio.get(
      "me/player"
    );

    if (response.statusCode == 200 && notifyListeners) {
      var json = response.data;

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

  Future<Response> getLikedPlaylists(int limit, int offset) async {

    final response = await dio.get(
      "me/playlists",
      queryParameters: {
        "limit" : limit.toString(),
        "offset" : offset.toString()
      },
    );

    return response;
  }

  Future<Response> queue(String uri, {String deviceId = ""}) async {

    final response = await dio.post(
      "me/player/queue",
      queryParameters: {
        "uri": uri,
        if(deviceId.isNotEmpty) "device_id": deviceId
      }
    );

    //debugPrint(response.body.toString());

    return response;
  }

  Future<Response> searchSpotify(String query, int limit, int offset) async {
    final response = await dio.get(
      "search",
      queryParameters: {
        'q': query,
        'type': 'track,album,playlist',
        'limit': limit,
        'offset': offset,
      },
    );

    return response;
  }

  Future<Response> playTracks(List<String> uris, {String deviceId = ""}) async {

    final Map<String, dynamic> payload = {"uris": uris};

    final response = await dio.put(
      "me/player/play",
      options: Options(headers: {'Content-Type': 'application/json'}),
      queryParameters: {
        if(deviceId.isNotEmpty) "device_id" : deviceId
      },
      data: jsonEncode(payload),
    );


    return response;
  }

  Future<Response> transferPlayback(String deviceId) async {
    final dynamic payload = {"device_ids": [ deviceId ]};

    final response = await dio.put(
      "/me/player",
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: jsonEncode(payload),
    );

    return response;
  }
}
