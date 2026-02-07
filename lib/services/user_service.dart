import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/users/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user'] ?? data);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<UserModel> updateProfile(UserProfileUpdateRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.apiBaseUrl}/users/me'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/users/change-password'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/users/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['avatarUrl'] ?? data['avatar'] ?? '';
      } else {
        final error = jsonDecode(responseData);
        throw Exception(error['message'] ?? 'Failed to upload avatar');
      }
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/users/me'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }
}
