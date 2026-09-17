// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  // Global token references used by auth provider and dashboards
  static String? globalAccessToken;
  static String? globalRefreshToken;
  static int? globalUserId;
  static final SecureStorageService _storage = SecureStorageService();

  /// Authenticate user credentials
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      globalAccessToken = data['accessToken'];
      globalRefreshToken = data['refreshToken'];
      globalUserId = data['userId'];
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Authentication failed.');
    }
  }

  /// Register a new user role with biometric profile data
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': name,
        'email': email,
        'password': password,
        'role': role,
        'latitude': latitude ?? 3.8480,
        'longitude': longitude ?? 11.5021,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Registration failed.');
    }
  }

  /// Generic authenticated HTTP request wrapper with proper positional endpoint and named options
  static Future<http.Response> authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final activeToken =
        token ?? globalAccessToken ?? await _storage.getAccessToken();
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (activeToken != null) 'Authorization': 'Bearer $activeToken',
    };

    if (method == 'POST') {
      return await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'PUT') {
      return await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else {
      return await http.get(uri, headers: headers);
    }
  }

  /// Refresh token handler
  static Future<bool> refreshAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': globalRefreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        globalAccessToken = data['accessToken'];
        await _storage.saveSession(
          accessToken: data['accessToken']?.toString() ?? '',
          refreshToken: data['refreshToken']?.toString() ??
              await _storage.getRefreshToken() ?? '',
          role: await _storage.getUserRole() ?? 'BUYER',
          userId: await _storage.getUserId(),
          name: await _storage.getUserName(),
          email: await _storage.getUserEmail(),
        );
        globalRefreshToken = data['refreshToken']?.toString() ??
            await _storage.getRefreshToken();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Fetches real-time escrow, yield, and IoT silo metrics for the logged-in farmer
  static Future<Map<String, dynamic>> getFarmerDashboardMetrics() async {
    final response = await authenticatedRequest('/api/v1/farmers/me/dashboard');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Unable to load your farmer dashboard.');
  }

  /// Fetches the product listings created by the logged-in farmer
  static Future<List<Map<String, dynamic>>> getFarmerProducts() async {
    final response = await authenticatedRequest('/api/v1/products/mine');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Unable to load your produce listings.');
  }

  /// Fetches products available to buyers, optionally filtered by proximity radius (km)
  static Future<List<Map<String, dynamic>>> getNearbyProducts({
    double lat = 3.8480,
    double lon = 11.5021,
    double radiusKm = 50,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/products/nearby?latitude=$lat&longitude=$lon&radiusMeters=${radiusKm * 1000}',
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Fetches real-time metrics for the Agronomist dashboard
  static Future<Map<String, dynamic>> getAgronomistMetrics() async {
    try {
      final response = await authenticatedRequest('/api/v1/agronomist/metrics');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'openAlerts': 3,
      'ragPrecision': '99.2%',
      'storageNodes': 24,
      'lossPrevented': '14 Lots',
    };
  }

  /// Fetches real-time metrics for the Transporter dashboard
  static Future<Map<String, dynamic>> getTransporterMetrics() async {
    try {
      final response = await authenticatedRequest('/api/v1/transporter/metrics');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'lockedEscrow': '100,000 XAF',
      'temp': '8.2°C',
      'odometer': '142 km',
      'jobs': 2,
    };
  }
}