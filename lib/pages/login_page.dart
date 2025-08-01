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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});


  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: GetIt.instance.get<SpotifyService>().getClientId);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
          width: 300,
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Enter client id',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          SizedBox(height: 10,),
          ElevatedButton(
            onPressed: () async {
              SpotifyService spotifyService = GetIt.instance
                  .get<SpotifyService>();

              spotifyService.setClientId(textController.text);
              await FlutterSecureStorage().write(key: "client_id", value: textController.text);

              String codeVerifier = Auth.generateRandomString(64);
              String codeChallenge = base64UrlEncode(Auth.sha256(codeVerifier));
              codeChallenge = codeChallenge.replaceAll("=", "");

              Uri url = Uri.parse('https://accounts.spotify.com/authorize')
                  .replace(
                    queryParameters: {
                      'response_type': 'code',
                      'client_id': spotifyService.getClientId,
                      'scope': _scope,
                      'code_challenge_method': 'S256',
                      'code_challenge': codeChallenge,
                      'redirect_uri': 'http://127.0.0.1:3434',
                    },
                  );

              var promise = loopbackAuthorize(authorizeUrl: url);
              var result = await promise;

              String code = result.toString().split("code=").last;

              Map<String, dynamic> json = await spotifyService.pkceRequestToken(
                code,
                codeVerifier,
              );
              String token = json["access_token"];

              if (context.mounted) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                final storage = FlutterSecureStorage();
                await storage.write(key: "token", value: token);

                if (json.containsKey("refresh_token")) {
                  String refreshToken = json["refresh_token"];
                  await storage.write(
                    key: "refresh_token",
                    value: refreshToken,
                  );
                  spotifyService.setRefreshToken(refreshToken);
                }

                spotifyService.setToken(token);
                authProvider.setIsAuthenticated(true);
              }
            },

            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Color(0xff1DB954)),
            ),
            child: Text(
              "Login To Spotify",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
