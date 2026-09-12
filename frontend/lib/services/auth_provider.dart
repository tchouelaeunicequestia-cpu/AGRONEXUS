import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  
  bool _isAuthenticated = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  // Check storage on app startup
  Future<void> tryAutoLogin() async {
    _token = await _storageService.getToken();
    if (_token != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Login: save token locally and update state
  Future<void> login(String jwtToken) async {
    _token = jwtToken;
    _isAuthenticated = true;
    await _storageService.saveToken(jwtToken);
    notifyListeners();
  }

  // Logout: clear token locally and update state
  Future<void> logout() async {
    _token = null;
    _isAuthenticated = false;
    await _storageService.deleteToken();
    notifyListeners();
  }
}