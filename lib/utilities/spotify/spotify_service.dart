import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify/playback_state.dart';
import 'package:lightify/utilities/spotify/spotify_http_client.dart';
import "package:http/http.dart" as http_lib;

part 'service_parts/player.dart';
part 'service_parts/auth.dart';

class SpotifyService {
  late final SpotifyHttpClient http;
  final FlutterSecureStorage _storage;
  final AuthProvider _authProvider;
  late Function? updatePlayerToken;

  String token = "";
  String refreshToken = "";

  final _playbackStateCtrl = StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get onPlaybackStateChanged => _playbackStateCtrl.stream;

  SpotifyService({
    required FlutterSecureStorage storage,
    required AuthProvider authProvider,
  }) : _storage = storage,
       _authProvider = authProvider {
    http = SpotifyHttpClient(
      onUnauthorized: () async {
        debugPrint("HTTP Client had a problem with the token");
      },
      spotifyService: this

    );
  }

  void dispose() {
    _playbackStateCtrl.close();
  }
}
