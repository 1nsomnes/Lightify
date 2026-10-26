import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lightify/providers/auth_provider.dart';
import 'package:lightify/utilities/spotify/playback_state.dart';
import 'package:lightify/utilities/spotify/spotify_http_client.dart';

part 'service_parts/player.dart';
part 'service_parts/auth.dart';
part 'service_parts/browse.dart';

class SpotifyService {
  final FlutterSecureStorage _storage;
  final AuthProvider _authProvider;
  late Function? updatePlayerToken;
  late final SpotifyHttpClient http;
  late final Dio dio;

  final _playbackStateCtrl = StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get onPlaybackStateChanged => _playbackStateCtrl.stream;

  SpotifyService({
    required FlutterSecureStorage storage,
    required AuthProvider authProvider,
  }) : _storage = storage,
       _authProvider = authProvider {
    http = SpotifyHttpClient(
      onUnauthorized: () =>
          debugPrint("HTTP Client had a problem with the token"),
      spotifyService: this,
    );

    dio = Dio(BaseOptions(baseUrl: "https://api.spotify.com/v1/"));

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final opts = error.requestOptions;
          final response = error.response;
          final statusCode = response?.statusCode;
          debugPrint(
            "Spotify API error $statusCode on ${opts.path}: ${response?.data}",
          );
          if (statusCode == 401 &&
              opts.extra["__retry"] != true &&
              await attemptRefresh()) {
            opts.headers["Authorization"] = "Bearer $_token";
            opts.extra["__retry"] = true;
            try {
              return handler.resolve(await dio.fetch(opts));
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  String _token = "";
  String _refreshToken = "";
  String _clientId = "";
  String _deviceId = "";
  Future<bool>? _refreshInFlight;

  String get getToken => _token;
  String get getRefreshToken => _refreshToken;
  String get getClientId => _clientId;
  String get getDeviceId => _deviceId;

  void setToken(String token) {
    _token = token;
    dio.options.headers["Authorization"] = "Bearer $token";
  }

  void setRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
  }

  void setClientId(String clientId) {
    _clientId = clientId;
  }

  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  void dispose() {
    _playbackStateCtrl.close();
  }
}
