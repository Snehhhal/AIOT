import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_localizations.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  AppLanguage _currentLanguage = AppLanguage.en;
  bool _isOffline = false;
  UserRole _selectedRole = UserRole.citizen;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole get currentRole => _currentUser?.role ?? _selectedRole;
  UserRole get selectedRole => _selectedRole;
  AppLanguage get currentLanguage => _currentLanguage;
  bool get isOffline => _isOffline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    checkSavedSession();
  }

  void setSelectedRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  void toggleOfflineMode() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  /// Restores session on app startup if JWT token exists in SharedPreferences
  Future<void> checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_profile');

      if (token != null && token.isNotEmpty && userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(decoded);
        ApiClient.setAuthToken(token);
        _selectedRole = _currentUser!.role;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Real authentication against FastAPI backend
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiClient.login(email.trim(), password);

    _isLoading = false;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final token = data['access_token'] as String;

      userMap['token'] = token;
      _currentUser = UserModel.fromJson(userMap);
      _selectedRole = _currentUser!.role;

      // Persist to local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_profile', jsonEncode(_currentUser!.toJson()));
      } catch (_) {}

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] as String? ?? 'Login failed.';
      notifyListeners();
      return false;
    }
  }

  /// Real registration against FastAPI backend
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? zone,
    String? staffAuthCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiClient.register(
      email: email.trim(),
      password: password,
      fullName: fullName.trim(),
      role: role,
      zone: zone,
      staffAuthCode: staffAuthCode,
    );

    _isLoading = false;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final token = data['access_token'] as String;

      userMap['token'] = token;
      _currentUser = UserModel.fromJson(userMap);
      _selectedRole = _currentUser!.role;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_profile', jsonEncode(_currentUser!.toJson()));
      } catch (_) {}

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] as String? ?? 'Registration failed.';
      notifyListeners();
      return false;
    }
  }

  /// Request password reset verification code
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await ApiClient.forgotPassword(email.trim());
  }

  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    return await ApiClient.resetPassword(
      email: email.trim(),
      token: token.trim(),
      newPassword: newPassword,
    );
  }

  /// Logs out user and clears persisted session
  Future<void> logout() async {
    _currentUser = null;
    ApiClient.setAuthToken('');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_profile');
    } catch (_) {}
    notifyListeners();
  }
}
