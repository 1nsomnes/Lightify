import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/loopback.dart';
import 'package:lightify/utilities/spotify_auth.dart';
import 'package:provider/provider.dart';

final Uri url = Uri.parse(
  'https://accounts.spotify.com/authorize?client_id=3c3d7b0f935849bf82a7ce3153e1581b&response_type=code&redirect_uri=http://127.0.0.1:3434&scope=streaming%20playlist-read-private%20user-read-email%20user-read-private%20user-library-read%20user-library-modify%20user-read-playback-state%20user-modify-playback-state',
);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          var promise = loopbackAuthorize(authorizeUrl: url);
          var result = await promise;

          String code = result.toString().split("code=").last;

          Map<String, dynamic> json = await debugRequestToken(code);
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
              await storage.write(key: "refresh_token", value: refreshToken);
              authProvider.setRefreshToken(refreshToken);
            }

            authProvider.setToken(token);
            authProvider.setIsAuthenticated(true);
          }
        },

        style: const ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(Color(0xff1DB954)),
        ),
        child: Text("Login To Spotify", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
