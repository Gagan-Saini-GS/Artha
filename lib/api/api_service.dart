import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  // Optional: You can pass your JWT token here
  final String? authToken;

  ApiService({required this.baseUrl, this.authToken});

  // GET request
  // Future<dynamic> get(String endpoint) async {
  //   final response = await http.get(
  //     Uri.parse('$baseUrl$endpoint'),
  //     headers: _buildHeaders(),
  //   );
  //   return _processResponse(response);
  // }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _buildHeaders());
    return _processResponse(response);
  }

  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  // PATCH request
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  // DELETE request
  Future<dynamic> delete(String endpoint, Map<String, dynamic> body) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  // Builds the request headers
  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  // Handles status codes & errors
  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    final message = (body is Map && body['message'] != null)
        ? body['message'] as String
        : 'Request failed';
    throw Exception('$statusCode: $message');
  }
}
