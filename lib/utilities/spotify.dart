import "dart:convert";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;

//TODO: create spotify client that handles errors universally

Future<http.Response> getPlaybackStateByToken(String token) async {
  final uri = Uri.parse('https://api.spotify.com/v1/me/player');

  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );

  return response;
}

Future<http.Response> searchSpotify(
  String query,
  int limit,
  int offset,
  String token,
) async {
  final url = Uri.parse("https://api.spotify.com/v1/search").replace(
    queryParameters: {
      "q": query,
      "type": "track,album,playlist",
      "limit": limit.toString(),
      "offset": offset.toString(),
    },
  );

  debugPrint(url.toString());

  final response = await http.get(
    url,

    headers: {'Authorization': 'Bearer $token'},
  );

  return response;
}

Future<http.Response> playTracks(
  List<String> uris,
  String token, {
  String deviceId = "",
}) async {
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

  debugPrint(response.body.toString());

  return response;
}


Future<http.Response> playPlaylistOrAlbums(
  String uri,
  String token, {
  String deviceId = "",
}) async {
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

  debugPrint(response.body.toString());
  
  return response;
}

Future<http.Response> queue(String uri, String token, {String deviceId = ""}) async {
  Uri url = Uri.parse("https://api.spotify.com/v1/me/player/queue");
  if (deviceId.isNotEmpty) {
    url = url.replace(queryParameters: {"uri": uri, "device_id": deviceId});
  } else {
    url = url.replace(queryParameters: {"uri": uri});
  }


  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  
  debugPrint(response.body.toString());

  return response;
}
