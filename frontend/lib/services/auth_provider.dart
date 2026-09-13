import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  bool _isAuthenticated = false;
  String? _role;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;

  Future<void> tryAutoLogin() async {
    final accessToken = await _storageService.getAccessToken();
    _role = await _storageService.getUserRole();

    if (accessToken != null) {
      _isAuthenticated = true;
      notifyListeners();
    } else {
      bool refreshed = await ApiService.refreshAccessToken();
      _isAuthenticated = refreshed;
      if (_isAuthenticated) {
        _role = await _storageService.getUserRole();
      }
      notifyListeners();
    }
  }

  Future<void> login(Map<String, dynamic> authData) async {
    _isAuthenticated = true;
    _role = authData['role'];
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _role = null;
    await _storageService.clearSession();
    notifyListeners();
  }
}