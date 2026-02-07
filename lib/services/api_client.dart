import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

/// API Client for connecting to the backend
class ApiClient {
  static const String baseUrl = 'https://longest-ice-production.up.railway.app';
  static const String apiVersion = '/api';
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;
  
  /// Get current auth token
  String? get token => _authToken;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null;

  /// Initialize and load token from storage
  Future<void> initialize() async {
    await _loadToken();
  }

  /// Load token from SharedPreferences
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  /// Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Clear token from storage
  Future<void> clearToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  /// Build full API URL
  String _buildUrl(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$apiVersion$cleanEndpoint';
  }

  /// Get default headers with auth token
  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    // Handle specific error cases
    String message = 'An error occurred';
    Map<String, dynamic>? errors;

    if (body != null) {
      message = body['message'] ?? body['error'] ?? message;
      errors = body['errors'] as Map<String, dynamic>?;
    }

    switch (statusCode) {
      case 400:
        throw ApiException(message: message, statusCode: statusCode, errors: errors);
      case 401:
        // Token expired or invalid
        clearToken();
        throw ApiException(message: 'Session expired. Please login again.', statusCode: statusCode);
      case 403:
        throw ApiException(message: 'Access denied', statusCode: statusCode);
      case 404:
        throw ApiException(message: message, statusCode: statusCode);
      case 422:
        throw ApiException(message: message, statusCode: statusCode, errors: errors);
      case 500:
      case 502:
      case 503:
        throw ApiException(message: 'Server error. Please try again later.', statusCode: statusCode);
      default:
        throw ApiException(message: message, statusCode: statusCode);
    }
  }

  // ==================== HTTP Methods ====================

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      var url = Uri.parse(_buildUrl(endpoint));
      
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        url,
        headers: _getHeaders(requiresAuth: requiresAuth),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));

      final response = await http.post(
        url,
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));

      final response = await http.put(
        url,
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));

      final response = await http.patch(
        url,
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));

      final response = await http.delete(
        url,
        headers: _getHeaders(requiresAuth: requiresAuth),
      );

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }

  /// Upload file (multipart/form-data)
  Future<dynamic> uploadFile(
    String endpoint, {
    required String filePath,
    String fieldName = 'file',
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final request = http.MultipartRequest('POST', url);

      // Add headers
      if (requiresAuth && _authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Network error: $e', statusCode: 0);
    }
  }
}
