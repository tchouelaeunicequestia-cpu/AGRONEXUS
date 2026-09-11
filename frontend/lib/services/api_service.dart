import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

Future<String> testConnection() async {
  try {
    // Targeting your actual AuthController login endpoint
    final url = Uri.parse('$baseUrl/api/v1/auth/login');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test@agronexus.com',
        'password': 'dummyPassword'
      }),
    );
    
    // Based on your AuthController, bad credentials return a 401 Unauthorized.
    // If we get a 401, it means the server received the request and processed it!
    if (response.statusCode == 401) {
      return 'Connection Successful! (Received expected 401 from AuthController)';
    } else if (response.statusCode == 200) {
      return 'Success: ${response.body}';
    } else {
      return 'Server reached, but returned unexpected status: ${response.statusCode}';
    }
  } catch (e) {
    return 'Connection Failed: $e';
  }
}