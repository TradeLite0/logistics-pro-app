import '../models/user_model.dart';
import 'api_client.dart';

/// Response from authentication operations
class AuthResponse {
  final bool success;
  final String? message;
  final User? user;
  final String? token;

  AuthResponse({
    required this.success,
    this.message,
    this.user,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
    );
  }
}

/// Service for authentication operations
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Initialize auth service (load saved token)
  Future<void> initialize() async {
    await _apiClient.initialize();
  }

  /// Check if user is logged in
  bool get isLoggedIn => _apiClient.isAuthenticated;

  /// Get current auth token
  String? get token => _apiClient.token;

  // ==================== Authentication ====================

  /// Login with phone and password
  Future<AuthResponse> login({
    required String phone,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'phone': phone,
          'password': password,
          'fcm_token': fcmToken,
        },
        requiresAuth: false,
      );

      // Save token if login successful
      if (response['token'] != null) {
        await _apiClient.saveToken(response['token']);
      }

      return AuthResponse.fromJson(response);
    } on ApiException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Login failed: $e',
      );
    }
  }

  /// Register new user
  Future<AuthResponse> register({
    required String phone,
    required String password,
    required String name,
    required UserRole role,
    String? email,
    String? fcmToken,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        body: {
          'phone': phone,
          'password': password,
          'name': name,
          'type': role.key,
          'email': email,
          'fcm_token': fcmToken,
        },
        requiresAuth: false,
      );

      // Save token if registration successful
      if (response['token'] != null) {
        await _apiClient.saveToken(response['token']);
      }

      return AuthResponse.fromJson(response);
    } on ApiException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Registration failed: $e',
      );
    }
  }

  /// Request password reset
  Future<AuthResponse> forgotPassword(String phone) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        body: {'phone': phone},
        requiresAuth: false,
      );

      return AuthResponse.fromJson(response);
    } on ApiException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Request failed: $e',
      );
    }
  }

  /// Reset password with token
  Future<AuthResponse> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/reset-password',
        body: {
          'token': token,
          'password': newPassword,
        },
        requiresAuth: false,
      );

      return AuthResponse.fromJson(response);
    } on ApiException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Reset failed: $e',
      );
    }
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      
      if (response['user'] != null) {
        return User.fromJson(response['user']);
      }
      return null;
    } on ApiException catch (e) {
      print('Error getting current user: ${e.message}');
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Update user profile
  Future<AuthResponse> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;

      final response = await _apiClient.put('/auth/profile', body: body);

      return AuthResponse.fromJson(response);
    } on ApiException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Update failed: $e',
      );
    }
  }

  /// Change password
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return AuthResponse.fromJson(response);
    } on ApiException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Change password failed: $e',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Optional: Call logout endpoint to invalidate token on server
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore error, still clear local token
    } finally {
      await _apiClient.clearToken();
    }
  }
}
