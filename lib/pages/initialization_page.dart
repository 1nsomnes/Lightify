import 'package:flutter/material.dart';
import 'package:lightify/pages/home_page.dart';
import 'package:lightify/pages/loading_page.dart';
import 'package:lightify/pages/login_page.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/utilities/spotify_auth.dart';
import 'package:provider/provider.dart';


class InitializationPage extends StatelessWidget {
  const InitializationPage({super.key});

  // returns "false" iff there is a response that is not positive or token authentication error

  // This means there is an unknown error because the API changed, wifi is not working, etc... In which
  // case we can send the user to a page informing them that some unknown error occurred
  Future<bool> initializeApp(BuildContext context) async {
    AuthProvider authProvider;
    if (context.mounted) {
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    } else {
      // this should never happen so return false here too
      return false;
    }

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: "token");

    if (token != null) {
      final result = await isValidToken(token);
      if (result == AuthError.invalid) {
        authProvider.setIsAuthenticated(false);
      } else if (result == AuthError.valid) {
        authProvider.setIsAuthenticated(true);
        authProvider.setToken(token);
      } else {
        return false; //some strange error has happened
      }
    } else {
      authProvider.setIsAuthenticated(false);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeApp(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingPage();
        }

        if (snapshot.data == true) {
          final authProvider = Provider.of<AuthProvider>(context);
          if (authProvider.isAuthenticated) {
            return HomePage();
          } else {
            return LoginPage();
          }
        } else {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text("Fatal error occured. Please restart the app."),
              ),
            ),
          );
        }
      },
    );
  }
}
