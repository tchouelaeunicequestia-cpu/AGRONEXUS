import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;

  // Getters for the UI to read the state
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  // Method to update state after a successful login/logout
  void setAuthStatus(bool status, {String? jwtToken}) {
    _isAuthenticated = status;
    _token = jwtToken;
    
    // This tells all screens watching this provider to rebuild!
    notifyListeners(); 
  }
}