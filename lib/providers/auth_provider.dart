
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "BQB4KFDWxamjB82Vu8kk1-u2uGGM8uWUI8Gr09sxQRCy3EAtVb4_rLFrh6cPm5gXXVEqKKpcSzDFbab5Ju_SS_vgIqL9ny33nDv-wbGIMII8TAE2SjvUcUw7zubArfbjCnmLlFvcxgY3r3NnMUNpp11JHf4nSM1fZy6eel8FQqyp3TqzMjyjrpBWb49FDuSBFb3HpfHOstdKnU6-gJZwXeI09qz0mHp9VZune_SBzd3rOeS9744-rjBA9lbIY1XTo8iu";
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
