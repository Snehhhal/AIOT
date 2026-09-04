import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_localizations.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  AppLanguage _currentLanguage = AppLanguage.en;
  bool _isOffline = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserRole get currentRole => _currentUser?.role ?? UserRole.citizen;
  AppLanguage get currentLanguage => _currentLanguage;
  bool get isOffline => _isOffline;

  AuthService() {
    // Start with default demo user: Citizen for clean onboarding
    _currentUser = null;
  }

  void setLanguage(AppLanguage lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  void toggleOfflineMode() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    // Standard credential check / demo fallback
    UserRole assignedRole = UserRole.citizen;
    String name = 'User';

    if (email.contains('tech')) {
      assignedRole = UserRole.technician;
      name = AppConstants.demoTechnician['name']!;
    } else if (email.contains('eng')) {
      assignedRole = UserRole.engineer;
      name = AppConstants.demoEngineer['name']!;
    } else if (email.contains('auth')) {
      assignedRole = UserRole.authority;
      name = AppConstants.demoAuthority['name']!;
    } else if (email.contains('admin')) {
      assignedRole = UserRole.admin;
      name = AppConstants.demoAdmin['name']!;
    } else {
      assignedRole = UserRole.citizen;
      name = AppConstants.demoCitizen['name']!;
    }

    _currentUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: assignedRole,
      zone: 'Sector 3 - Urban North',
      token: 'mock-jwt-token-${assignedRole.id}',
    );

    ApiClient.setAuthToken(_currentUser!.token ?? '');
    notifyListeners();
    return true;
  }

  void quickDemoLogin(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        _currentUser = UserModel(
          id: 'USR-CIT-01',
          name: AppConstants.demoCitizen['name']!,
          email: AppConstants.demoCitizen['email']!,
          role: UserRole.citizen,
          zone: 'Sector 4',
          token: 'demo-token-citizen',
        );
        break;
      case UserRole.technician:
        _currentUser = UserModel(
          id: 'USR-TECH-14',
          name: AppConstants.demoTechnician['name']!,
          email: AppConstants.demoTechnician['email']!,
          role: UserRole.technician,
          zone: 'Zone 1 & 2',
          token: 'demo-token-technician',
        );
        break;
      case UserRole.engineer:
        _currentUser = UserModel(
          id: 'USR-ENG-02',
          name: AppConstants.demoEngineer['name']!,
          email: AppConstants.demoEngineer['email']!,
          role: UserRole.engineer,
          zone: 'Sub-Division Central',
          token: 'demo-token-engineer',
        );
        break;
      case UserRole.authority:
        _currentUser = UserModel(
          id: 'USR-AUTH-01',
          name: AppConstants.demoAuthority['name']!,
          email: AppConstants.demoAuthority['email']!,
          role: UserRole.authority,
          zone: 'Municipal Circle',
          token: 'demo-token-authority',
        );
        break;
      case UserRole.admin:
        _currentUser = UserModel(
          id: 'USR-ADM-00',
          name: AppConstants.demoAdmin['name']!,
          email: AppConstants.demoAdmin['email']!,
          role: UserRole.admin,
          zone: 'All Distribution Zones',
          token: 'demo-token-admin',
        );
        break;
    }
    if (_currentUser?.token != null) {
      ApiClient.setAuthToken(_currentUser!.token!);
    }
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    ApiClient.setAuthToken('');
    notifyListeners();
  }
}
