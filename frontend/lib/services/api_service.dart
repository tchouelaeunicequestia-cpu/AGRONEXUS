import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Dynamically resolve backend host based on execution platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    } else if (Platform.isAndroid) {
      // Laptop's active IPv4 Address on 'HOUSE DESIGN' Wi-Fi network
      return 'http://192.168.1.133:8080/api/v1';
    } else {
      // Windows Desktop
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
      throw Exception(errorData['error'] ?? errorData['message'] ?? response.body);
    }
  }

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Invalid email or password');
    }
  }
}