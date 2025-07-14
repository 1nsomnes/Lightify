part of '../spotify_service.dart';

extension Auth on SpotifyService {
  Future<bool> attemptRefresh(String refreshToken) async {
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
    token = newToken;

    if (refreshResponse.containsKey("refresh_token")) {
      String newRefreshToken = refreshResponse["refresh_token"];
      await _storage.write(key: "refreshToken", value: refreshToken);
      refreshToken = newRefreshToken;
    }

    return true;
  }

  Future<Map<String, dynamic>?> requestTokenFromRefresh() async {
    final uri = Uri.parse('https://accounts.spotify.com/api/token');

    await dotenv.load(fileName: ".env");
    String? auth = dotenv.env["client"];

    if (auth == null) return {"Error": "Could not find client secrets"};

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic $auth',
      },
      body: {'refresh_token': refreshToken, 'grant_type': 'refresh_token'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    }
    debugPrint("failed refresh");

    return null;
  }
}
