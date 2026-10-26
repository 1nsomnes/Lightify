import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/loopback.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:provider/provider.dart';

const _scope =
    'streaming playlist-read-private user-read-email user-read-private user-library-read user-library-modify user-read-playback-state user-modify-playback-state';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final SpotifyService _spotifyService = GetIt.instance.get<SpotifyService>();
  final FlutterSecureStorage _storage = GetIt.instance
      .get<FlutterSecureStorage>();
  late final TextEditingController _textController = TextEditingController(
    text: _spotifyService.getClientId,
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final clientId = _textController.text;
    _spotifyService.setClientId(clientId);
    await _storage.write(key: "client_id", value: clientId);

    final codeVerifier = Auth.generateRandomString(64);
    final codeChallenge = base64UrlEncode(
      Auth.sha256(codeVerifier),
    ).replaceAll("=", "");

    final url = Uri.parse('https://accounts.spotify.com/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'scope': _scope,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'redirect_uri': 'http://127.0.0.1:3434',
      },
    );

    final result = await loopbackAuthorize(authorizeUrl: url);

    final code = result.queryParameters["code"];
    if (code == null) {
      debugPrint(
        "Spotify authorization failed: ${result.queryParameters["error"]}",
      );
      return;
    }

    final Map<String, dynamic> json = await _spotifyService.pkceRequestToken(
      code,
      codeVerifier,
    );
    final String? token = json["access_token"];
    if (token == null || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? refreshToken = json["refresh_token"];

    await Future.wait([
      _storage.write(key: "token", value: token),
      if (refreshToken != null)
        _storage.write(key: "refresh_token", value: refreshToken),
    ]);

    if (refreshToken != null) _spotifyService.setRefreshToken(refreshToken);
    _spotifyService.setToken(token);
    authProvider.setIsAuthenticated(true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Enter client id',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _login,
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Color(0xff1DB954)),
            ),
            child: const Text(
              "Login To Spotify",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
