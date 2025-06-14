
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "AQDOXmV2GoOxWvp6HW4GK56_8PSfj97OUEdTcPgPJAwm78Ir-sFWP5FTxFN1XJQQ92JKlilYgAxiaBmx46HIIzu1_DPbwE8xDr1byOyGw0_t_eH78e1jRPWUF9A4hLH7At9Y9VpNqxt2hAhvRRTA3ZQ7K3l5C-Bf9z3RxXnV59D7zWTy9DhFoeAY0upnu1H3xDTw-qYlbH_946jPi-MaS0X6hhu66NNmE35ljfG5XtVuLYBSjUl-kpsfWhbpGMLtdrnCDkCwRXPdbWYZK6L-QyQ5OwanWv2AGz86DE3u-ULXa7b-8ueKQonIG7put4_4GbfsXJSoAzU5SGd-jYv3O7PZ2ZvsXw";

  String get getToken => _token; 

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

}
