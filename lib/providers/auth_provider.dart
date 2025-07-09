import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "";
  String _refreshToken = "";
  bool _isAuthenticated = false;

  String get getToken => _token;
  String get getRefreshToken => _refreshToken;
  bool get isAuthenticated => _isAuthenticated;

  HotKey breakTokenKey = HotKey(
    key: PhysicalKeyboardKey.keyT,
    modifiers: [HotKeyModifier.control],
    scope: HotKeyScope.inapp,
  );

  AuthProvider() {
    _registerHotKey();
  }

  Future<void> _registerHotKey() async {
    await hotKeyManager.register(
      breakTokenKey,
      keyDownHandler: (_) async {
        setToken("break_token");
        await FlutterSecureStorage().write(key: "token", value: "break_token");

        debugPrint("attempted to break token");
      },
    );
  }

  void setIsAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void setRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
    notifyListeners();
  }
}
