
import 'package:lightify/utilities/spotify.dart';

enum AuthError { 
  valid,
  invalid,
  unknown
}

// https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback
// This link explains what these response codes mean, anything outside of the ones delineated below
// are unexpected behavior and should return unkown status codes 
Future<AuthError> isValidToken(String token) async {
  final response = await getPlaybackStateByToken(token);

  if(response.statusCode == 200 || response.statusCode == 204) {
    return AuthError.valid;
  } else if(response.statusCode == 401) {
    return AuthError.invalid;
  }

  return AuthError.unknown;
}
