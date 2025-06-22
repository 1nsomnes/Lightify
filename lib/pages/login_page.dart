import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:lightify/utilities/loopback.dart';

final Uri url = Uri.parse(
  'https://accounts.spotify.com/authorize?client_id=3c3d7b0f935849bf82a7ce3153e1581b&response_type=code&redirect_uri=http://127.0.0.1:3434&scope=streaming%20user-read-email%20user-read-private%20user-library-read%20user-library-modify%20user-read-playback-state%20user-modify-playback-state',
);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              var promise = loopbackAuthorize(authorizeUrl: url);
              FlutterForegroundTask.minimizeApp(); //TODO: fix this
              var result = await promise;

              String code = result.toString().split("code=").last;

              debugPrint(code);
            },

            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Color(0xff1DB954)),
            ),
            child: Text(
              "Login To Spotify",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
