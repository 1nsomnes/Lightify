
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "";

  String get getToken => _token; 

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

}
