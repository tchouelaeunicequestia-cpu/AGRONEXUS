import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';

class UserProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? role;

  UserProfile({this.id, this.name, this.email, this.role});
}

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  bool _isAuthenticated = false;
  String? _role;
  UserProfile? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  UserProfile? get currentUser => _currentUser;

  Future<void> tryAutoLogin() async {
    final accessToken = await _storageService.getAccessToken();
    _role = await _storageService.getUserRole();
    final name = await _storageService.getUserName();
    final email = await _storageService.getUserEmail();
    final id = await _storageService.getUserId();

    if (accessToken != null) {
      _isAuthenticated = true;
      ApiService.globalAccessToken = accessToken;
      ApiService.globalUserId = int.tryParse(id ?? '');
      _currentUser = UserProfile(id: id, name: name, email: email, role: _role);
      notifyListeners();
    } else {
      bool refreshed = await ApiService.refreshAccessToken();
      _isAuthenticated = refreshed;
      if (_isAuthenticated) {
        _role = await _storageService.getUserRole();
        ApiService.globalAccessToken = await _storageService.getAccessToken();
        ApiService.globalUserId = int.tryParse(await _storageService.getUserId() ?? '');
        _currentUser = UserProfile(id: id, name: name, email: email, role: _role);
      }
      notifyListeners();
    }
  }

  Future<void> login(Map<String, dynamic> authData) async {
    _isAuthenticated = true;
    ApiService.globalAccessToken = authData['accessToken']?.toString();
    ApiService.globalRefreshToken = authData['refreshToken']?.toString();
    ApiService.globalUserId = int.tryParse(authData['userId']?.toString() ?? '');
    _role = authData['role']?.toString();
    _currentUser = UserProfile(
      id: authData['userId']?.toString(),
      name: authData['fullName']?.toString() ?? authData['name']?.toString(),
      email: authData['email']?.toString(),
      role: _role,
    );

    // Persist profile data into secure storage
    await _storageService.saveSession(
      accessToken: authData['accessToken']?.toString() ?? '',
      refreshToken: authData['refreshToken']?.toString() ?? '',
      role: _role ?? 'BUYER',
      userId: _currentUser?.id,
      name: _currentUser?.name,
      email: _currentUser?.email,
    );

    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _role = null;
    _currentUser = null;
    ApiService.globalAccessToken = null;
    ApiService.globalRefreshToken = null;
    ApiService.globalUserId = null;
    await _storageService.clearSession();
    notifyListeners();
  }
}