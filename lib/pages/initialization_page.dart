import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lightify/pages/home_page.dart';
import 'package:lightify/pages/loading_page.dart';
import 'package:lightify/pages/login_page.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/providers/theme/darkTheme.dart';
import 'package:lightify/utilities/load_hotkeys.dart';
import 'package:lightify/utilities/spotify/spotify_service.dart';
import 'package:provider/provider.dart';

class InitializationPage extends StatefulWidget {
  const InitializationPage({super.key});

  @override
  State<InitializationPage> createState() => _InitializationPageState();
}

class _InitializationPageState extends State<InitializationPage> {
  late Future<bool> _future;
  late SpotifyService spotifyService;

  @override
  void initState() {
    super.initState();

    LoadHotKeys.loadHotKeys(restart);
    spotifyService = GetIt.instance.get<SpotifyService>();
    _runFuture();
  }

  void _runFuture() {
    _future = initializeApp(context);
  }
  

  // this restarts the intializaiton phase the hot keys need this funciton
  void restart() {
    setState(_runFuture);
  }

  // returns "false" iff there is a response that is not positive or token authentication error
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
    final refreshToken = await storage.read(key: "refresh_token");
    
    // make sure our SpotifyService (uses auth provider) has access to the tokens
    // before any of the SpotifyService calls are made
    if(token != null) spotifyService.token = token;
    if(refreshToken != null) spotifyService.refreshToken = refreshToken;

    if (token != null) {
      final result = await spotifyService.isValidToken(token);

      if (result == AuthError.invalid) {
        authProvider.setIsAuthenticated(false);
      } else if (result == AuthError.valid) {
        authProvider.setIsAuthenticated(true);
      } else {
        return false; //some strange error has happened
      }
    } else if (refreshToken != null) {
      
      spotifyService.attemptRefresh();
    } else {
      authProvider.setIsAuthenticated(false);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkMode,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: FutureBuilder(
          future: _future,
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
              return Center(
                child: Text("Fatal error occured. Please restart the app."),
              );
            }
          },
        ),
      ),
    );
  }
}
