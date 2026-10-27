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
    final bytes = crypto.sha256.convert(utf8.encode(data)).bytes;
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
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

  // Spotify rotates refresh tokens, so concurrent refreshes with the same
  // token would invalidate each other. Share a single in-flight refresh.
  Future<bool> attemptRefresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    debugPrint("Attempting to refresh tokens");
    final refreshResponse = await requestTokenFromRefresh();

    if (refreshResponse == null) {
      _authProvider.setIsAuthenticated(false);
      debugPrint("Refreshing token failed.");
      return false;
    }
    final String newToken = refreshResponse["access_token"];
    setToken(newToken);
    final writes = [_storage.write(key: "token", value: newToken)];

    if (refreshResponse.containsKey("refresh_token")) {
      _refreshToken = refreshResponse["refresh_token"];
      writes.add(_storage.write(key: "refresh_token", value: _refreshToken));
    }
    await Future.wait(writes);

    _authProvider.setIsAuthenticated(true);
    if (updatePlayerToken != null) updatePlayerToken!(_token);

    return true;
  }

  static final Uri _tokenUri = Uri.parse(
    'https://accounts.spotify.com/api/token',
  );

  Future<Map<String, dynamic>?> _postToken(
    Map<String, String> body,
    String failureLabel,
  ) async {
    final response = await http.post(
      _tokenUri,
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (response.statusCode == 200) return jsonDecode(response.body);

    debugPrint("$failureLabel: ${response.statusCode} ${response.body}");
    return null;
  }

  Future<Map<String, dynamic>?> requestTokenFromRefresh() {
    return _postToken({
      'refresh_token': _refreshToken,
      'grant_type': 'refresh_token',
      'client_id': _clientId,
    }, "failed refresh");
  }

  Future<Map<String, dynamic>> pkceRequestToken(
    String code,
    String codeVerifier,
  ) async {
    return await _postToken({
          'code': code,
          'redirect_uri': 'http://127.0.0.1:3434',
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'code_verifier': codeVerifier,
        }, "token exchange failed") ??
        {"Error": "Bad response"};
  }
}
