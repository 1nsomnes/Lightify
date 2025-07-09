import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "";
  String _refreshToken = "";
  bool _isAuthenticated = false;

  String get getToken => _token;
  String get getRefreshToken => _refreshToken;
  bool get isAuthenticated => _isAuthenticated;

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
