part of '../spotify_service.dart';

enum AuthError { valid, invalid, unknown }

// SPOTIFY AUTHORIZATION FLOW
// https://developer.spotify.com/documentation/web-api/tutorials/code-flow

// https://developer.spotify.com/documentation/web-api/reference/get-information-about-the-users-current-playback
// This link explains what these response codes mean, anything outside of the ones delineated below
// are unexpected behavior and should return unkown status codes
extension Auth on SpotifyService {
  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  static final Random _random = Random.secure();

  static String generateRandomString(int length) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
      ),
    );
  }

  static Uint8List sha256(String data) {
    final bytes = utf8.encode(data);
    final digest = crypto.sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  Future<AuthError> isValidToken(String token) async {
    final response = await getPlaybackState();
    if (response.statusCode == 200 || response.statusCode == 204) {
      return AuthError.valid;
    } else if (response.statusCode == 401) {
      return AuthError.invalid;
    }

    return AuthError.unknown;
  }

  Future<bool> attemptRefresh() async {
    final refreshResponse = await requestTokenFromRefresh();
    debugPrint("Attempting to refresh tokens");

    if (refreshResponse == null) {
      _authProvider.setIsAuthenticated(false);
      debugPrint("Refreshing token failed.");
      return false;
    }
    final String newToken = refreshResponse["access_token"];
    await _storage.write(key: "token", value: newToken);
    _authProvider.setIsAuthenticated(true);
    setToken(newToken);
    if (updatePlayerToken != null) updatePlayerToken!(_token);

    if (refreshResponse.containsKey("refresh_token")) {
      String newRefreshToken = refreshResponse["refresh_token"];
      await _storage.write(key: "refreshToken", value: _refreshToken);
      _refreshToken = newRefreshToken;
    }

    return true;
  }

  Future<Map<String, dynamic>?> requestTokenFromRefresh() async {
    final uri = Uri.parse('https://accounts.spotify.com/api/token');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'refresh_token': _refreshToken,
        'grant_type': 'refresh_token',
        'client_id': _clientId,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    }
    debugPrint("failed refresh");

    return null;
  }

  Future<Map<String, dynamic>> pkceRequestToken(
    String code,
    String codeVerifier,
  ) async {
    final uri = Uri.parse('https://accounts.spotify.com/api/token');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'redirect_uri': 'http://127.0.0.1:3434',
        'grant_type': 'authorization_code',
        'client_id': _clientId,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    }

    return {"Error": "Bad response"};
  }
}
