import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lightify/utilities/spotify.dart';
import "package:http/http.dart" as http;
import 'dart:convert';

enum AuthError { valid, invalid, unknown }

// SPOTIFY AUTHORIZATION FLOW
// https://developer.spotify.com/documentation/web-api/tutorials/code-flow

// https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback
// This link explains what these response codes mean, anything outside of the ones delineated below
// are unexpected behavior and should return unkown status codes
Future<AuthError> isValidToken(String token) async {
  final response = await getPlaybackStateByToken(token);

  if (response.statusCode == 200 || response.statusCode == 204) {
    return AuthError.valid;
  } else if (response.statusCode == 401) {
    return AuthError.invalid;
  }

  return AuthError.unknown;
}

//WARNING: DO NOT USE THIS IN PRODUCTION
Future<String> debugRequestToken(String code) async {
  final uri = Uri.parse('https://accounts.spotify.com/api/token');

  await dotenv.load(fileName: ".env");
  String? auth = dotenv.env["client"];

  if (auth == null) return "";

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'code' : code, 
      'redirect_uri': 'http://127.0.0.1:3434',
      'grant_type' : 'authorization_code'
    },
  );

  if(response.statusCode == 200) {
   final Map<String, dynamic> json = jsonDecode(response.body); 
   return json['access_token'];
  }

  return "";
}
