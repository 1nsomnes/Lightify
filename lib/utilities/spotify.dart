import "dart:collection";

import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;
import "package:lightify/providers/auth_provider.dart";
import "package:provider/provider.dart";

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
      "type": "track",
      "limit": limit.toString(),
      "offset": limit.toString(),
    },
  );

  debugPrint(url.toString());

  final response = await http.get(
    url,

    headers: {'Authorization': 'Bearer $token'},
  );

  return response;
}
