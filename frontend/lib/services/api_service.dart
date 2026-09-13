import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'secure_storage_service.dart';

class ApiService {
  static final SecureStorageService _storage = SecureStorageService();

  // Dynamically resolve backend host based on execution platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://192.168.1.133:8080/api/v1';
    } else {
      return 'http://localhost:8080/api/v1';
    }
  }

  // --- EPIC 1: AUTHENTICATION ---
  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name,
        'email': email,
        'password': password,
        'role': role,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['error'] ?? errorData['message'] ?? response.body,
      );
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Safe String Conversion & Null Extraction Guard
      final String accessToken = (data['accessToken'] ?? data['token'] ?? '')
          .toString();
      final String refreshToken = (data['refreshToken'] ?? '').toString();
      final String role = (data['role'] ?? 'BUYER').toString();

      if (accessToken.isEmpty) {
        throw Exception('Server returned an empty or missing access token.');
      }

      await _storage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: role,
      );
      return data;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Invalid email or password');
    }
  }

  // --- SILENT TOKEN REFRESH ENGINE ---
  static Future<bool> refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final currentRole = await _storage.getUserRole() ?? 'BUYER';

        final String newAccessToken =
            (data['accessToken'] ?? data['token'] ?? '').toString();
        final String newRefreshToken = (data['refreshToken'] ?? refreshToken)
            .toString();

        if (newAccessToken.isEmpty) return false;

        await _storage.saveSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          role: currentRole,
        );
        return true;
      } else {
        await _storage.clearSession();
        return false;
      }
    } catch (_) {
      await _storage.clearSession();
      return false;
    }
  }

  // --- AUTHENTICATED WRAPPER WITH AUTOMATIC 401 RETRY ---
  static Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    String? token = await _storage.getAccessToken();
    Uri uri = Uri.parse('$baseUrl$endpoint');
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };

    http.Response response = await _sendRequest(method, uri, headers, body);

    // If Access Token is expired (401), trigger silent refresh & retry once
    if (response.statusCode == 401) {
      bool refreshed = await refreshAccessToken();
      if (refreshed) {
        token = await _storage.getAccessToken();
        headers['Authorization'] = 'Bearer ${token ?? ""}';
        response = await _sendRequest(method, uri, headers, body);
      }
    }

    return response;
  }

  static Future<http.Response> _sendRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
    switch (method.toUpperCase()) {
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      case 'GET':
      default:
        return await http.get(uri, headers: headers);
    }
  }
}
