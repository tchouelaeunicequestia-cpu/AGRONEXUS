import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL for your Spring Boot Backend
  // Note: Use 'http://10.0.2.2:8080' for Android Emulator, or 'http://localhost:8080' for Windows/Web
  static const String baseUrl = 'http://localhost:8080/api/v1/auth';

  // Register User Endpoint
  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Registration failed');
    }
  }

  // Login User Endpoint
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Assuming your backend returns a JSON object containing the JWT token (e.g., { "token": "..." })
      return data['token'] ?? data['accessToken'];
    } else {
      throw Exception('Invalid email or password');
    }
  }
}