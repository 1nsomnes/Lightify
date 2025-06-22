import "package:flutter/widgets.dart";
import "package:http/http.dart" as http;
import "package:lightify/providers/auth_provider.dart";
import "package:provider/provider.dart";

Future<http.Response> getPlaybackState(BuildContext context) async {
  final uri = Uri.parse('https://api.spotify.com/v1/me/player');

  if(!context.mounted) {
    return http.Response("Context failed", 400);
  }

  final token = Provider.of<AuthProvider>(context, listen: false).getToken;


  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token'
    }
  );      // <-- async GET request

  return response;
}


Future<http.Response> getPlaybackStateByToken(String token) async {
  final uri = Uri.parse('https://api.spotify.com/v1/me/player');


  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token'
    }
  );      // <-- async GET request

  return response;
}
