
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "";
  bool _isAuthenticated = false;

  String get getToken => _token; 
  bool get isAuthenticated => _isAuthenticated;

  void setIsAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

}
