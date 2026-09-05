import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

import '../../citizen/screens/citizen_home_screen.dart';
import '../../citizen/screens/citizen_report_screen.dart';
import '../../citizen/screens/citizen_reports_screen.dart';
import '../../citizen/screens/citizen_chat_screen.dart';

import '../../technician/screens/technician_home_screen.dart';
import '../../technician/screens/technician_incidents_screen.dart';
import '../../technician/screens/technician_work_screen.dart';

import '../../engineer/screens/engineer_home_screen.dart';
import '../../engineer/screens/engineer_poles_screen.dart';
import '../../engineer/screens/engineer_incidents_screen.dart';

import '../../authority/screens/authority_home_screen.dart';
import '../../authority/screens/authority_escalations_screen.dart';
import '../../authority/screens/authority_zones_screen.dart';

import '../../admin/screens/admin_home_screen.dart';
import '../../admin/screens/admin_users_screen.dart';
import '../../admin/screens/admin_audit_screen.dart';

import '../../common/screens/profile_screen.dart';
import '../../common/widgets/connectivity_banner.dart';

class RoleShellScreen extends StatefulWidget {
  const RoleShellScreen({super.key});

  @override
  State<RoleShellScreen> createState() => _RoleShellScreenState();
}

class _RoleShellScreenState extends State<RoleShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = auth.currentRole;

    final pages = _getPagesForRole(role);
    final clampedIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.appName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(role.icon, size: 12, color: role.roleColor),
                const SizedBox(width: 4),
                Text(
                  role.displayName.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: role.roleColor, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Chip(
              backgroundColor: role.roleColor.withOpacity(0.15),
              side: BorderSide(color: role.roleColor.withOpacity(0.3)),
              avatar: Icon(role.icon, size: 14, color: role.roleColor),
              label: Text(
                auth.currentUser?.fullName.split(' ').first ?? role.displayName,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: role.roleColor),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout',
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: pages[clampedIndex]),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(role, clampedIndex),
    );
  }

  List<Widget> _getPagesForRole(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return const [
          CitizenHomeScreen(),
          CitizenReportsScreen(),
          CitizenReportScreen(),
          CitizenChatScreen(),
          ProfileScreen(),
        ];
      case UserRole.technician:
        return const [
          TechnicianHomeScreen(),
          TechnicianIncidentsScreen(),
          TechnicianWorkScreen(),
          CitizenChatScreen(),
          ProfileScreen(),
        ];
      case UserRole.engineer:
        return const [
          EngineerHomeScreen(),
          EngineerPolesScreen(),
          EngineerIncidentsScreen(),
          CitizenChatScreen(),
          ProfileScreen(),
        ];
      case UserRole.authority:
        return const [
          AuthorityHomeScreen(),
          AuthorityEscalationsScreen(),
          AuthorityZonesScreen(),
          AdminAuditScreen(),
          ProfileScreen(),
        ];
      case UserRole.admin:
        return const [
          AdminHomeScreen(),
          EngineerPolesScreen(),
          AdminUsersScreen(),
          AdminAuditScreen(),
          ProfileScreen(),
        ];
    }
  }

  Widget _buildBottomNav(UserRole role, int currentIndex) {
    List<BottomNavigationBarItem> items = [];

    switch (role) {
      case UserRole.citizen:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Safety Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'My Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo_rounded), label: 'Report Hazard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.technician:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman_rounded), label: 'Work Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'SOP Guide'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.engineer:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Fleet Health'),
          BottomNavigationBarItem(icon: Icon(Icons.electrical_services_rounded), label: 'Poles'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route_rounded), label: 'Dispatch'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'AI Anomaly'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.authority:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Zone Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.priority_high_rounded), label: 'Escalations'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Risk Zones'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Audit Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.admin:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Platform'),
          BottomNavigationBarItem(icon: Icon(Icons.electrical_services_rounded), label: 'Poles'),
          BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: 'Audit Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: AppTheme.surfaceDark,
      selectedItemColor: role.roleColor,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
      items: items,
    );
  }
}
