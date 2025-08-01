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
      onUnauthorized: () async {
        debugPrint("HTTP Client had a problem with the token");
      },
      spotifyService: this,
    );

    dio = Dio(
      BaseOptions(
        baseUrl: "https://api.spotify.com/v1/",
        headers: {'Authorization': 'Bearer $_token'},
      ),
    );

    dio.interceptors.addAll([
      //LogInterceptor(requestBody: true, responseBody: true),
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          var opts = error.requestOptions;
          if (error.response?.statusCode == 401 &&
              opts.extra["__retry"] != true &&
              await attemptRefresh()) {
            opts.headers["Authorization"] = "Bearer $_token";
            opts.extra["__retry"] = true;
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
          return handler.next(error);
        },
      ),
    ]);
  }

  String _token = "";
  String _refreshToken = "";
  String _clientId = "";
  String _deviceId = "";

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
