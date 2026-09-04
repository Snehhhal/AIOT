import 'package:flutter/material.dart';

enum UserRole {
  citizen,
  technician,
  engineer,
  authority,
  admin,
}

extension UserRoleExtension on UserRole {
  String get id {
    switch (this) {
      case UserRole.citizen:
        return 'CITIZEN';
      case UserRole.technician:
        return 'TECHNICIAN';
      case UserRole.engineer:
        return 'ENGINEER';
      case UserRole.authority:
        return 'AUTHORITY';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.technician:
        return 'Field Technician';
      case UserRole.engineer:
        return 'Engineer / Supervisor';
      case UserRole.authority:
        return 'Municipal Authority';
      case UserRole.admin:
        return 'System Administrator';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.citizen:
        return Icons.person_pin_circle_rounded;
      case UserRole.technician:
        return Icons.build_circle_rounded;
      case UserRole.engineer:
        return Icons.engineering_rounded;
      case UserRole.authority:
        return Icons.shield_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  Color get roleColor {
    switch (this) {
      case UserRole.citizen:
        return const Color(0xFF10B981); // Emerald Green
      case UserRole.technician:
        return const Color(0xFFF59E0B); // Amber
      case UserRole.engineer:
        return const Color(0xFF3B82F6); // Blue
      case UserRole.authority:
        return const Color(0xFF8B5CF6); // Purple
      case UserRole.admin:
        return const Color(0xFFEF4444); // Red
    }
  }
}

enum RiskTier {
  safe,
  warning,
  critical,
  emergency,
}

extension RiskTierExtension on RiskTier {
  String get label {
    switch (this) {
      case RiskTier.safe:
        return 'SAFE';
      case RiskTier.warning:
        return 'WARNING';
      case RiskTier.critical:
        return 'CRITICAL';
      case RiskTier.emergency:
        return 'EMERGENCY';
    }
  }

  Color get color {
    switch (this) {
      case RiskTier.safe:
        return const Color(0xFF10B981); // Green
      case RiskTier.warning:
        return const Color(0xFFF59E0B); // Amber
      case RiskTier.critical:
        return const Color(0xFFF97316); // Orange
      case RiskTier.emergency:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case RiskTier.safe:
        return Icons.check_circle_rounded;
      case RiskTier.warning:
        return Icons.warning_amber_rounded;
      case RiskTier.critical:
        return Icons.dangerous_rounded;
      case RiskTier.emergency:
        return Icons.crisis_alert_rounded;
    }
  }
}

class AppConstants {
  static const String appName = 'Electric Pole Safety';
  static const String appTagline = 'AI & IoT Leakage Detection and Life Safety Platform';
  static const String appVersion = '1.0.0 (Phase 1)';

  // Backend Defaults
  static const String defaultApiBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator
  static const String localHostApiBaseUrl = 'http://localhost:8000/api/v1';

  // Demo Accounts
  static const Map<String, String> demoCitizen = {
    'email': 'citizen@safety.org',
    'role': 'CITIZEN',
    'name': 'Rahul Sharma',
  };
  static const Map<String, String> demoTechnician = {
    'email': 'technician@safety.org',
    'role': 'TECHNICIAN',
    'name': 'Kailas Jadhav (Lineman #14)',
  };
  static const Map<String, String> demoEngineer = {
    'email': 'engineer@safety.org',
    'role': 'ENGINEER',
    'name': 'Er. Snehal Chavan (Sub-Div)',
  };
  static const Map<String, String> demoAuthority = {
    'email': 'authority@safety.org',
    'role': 'AUTHORITY',
    'name': 'Commissioner Office (Zone 3)',
  };
  static const Map<String, String> demoAdmin = {
    'email': 'admin@safety.org',
    'role': 'ADMIN',
    'name': 'Platform Root Administrator',
  };
}
