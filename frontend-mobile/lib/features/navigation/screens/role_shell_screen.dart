import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../admin/screens/admin_home_screen.dart';
import '../../authority/screens/authority_home_screen.dart';
import '../../citizen/screens/citizen_home_screen.dart';
import '../../common/widgets/connectivity_banner.dart';
import '../../engineer/screens/engineer_home_screen.dart';
import '../../technician/screens/technician_home_screen.dart';

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
    final user = auth.currentUser;
    final role = auth.currentRole;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(role.icon, size: 12, color: role.roleColor),
                const SizedBox(width: 4),
                Text(
                  role.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: role.roleColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick Role Switcher Button (Viva & Demo essential)
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: role.roleColor.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            icon: Icon(Icons.swap_horiz_rounded, size: 16, color: role.roleColor),
            label: Text(
              'Switch Role',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: role.roleColor),
            ),
            onPressed: () => _showRoleSwitchModal(context, auth),
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
          Expanded(child: _buildRoleHome(role)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(role),
    );
  }

  Widget _buildRoleHome(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return const CitizenHomeScreen();
      case UserRole.technician:
        return const TechnicianHomeScreen();
      case UserRole.engineer:
        return const EngineerHomeScreen();
      case UserRole.authority:
        return const AuthorityHomeScreen();
      case UserRole.admin:
        return const AdminHomeScreen();
    }
  }

  Widget _buildBottomNav(UserRole role) {
    List<BottomNavigationBarItem> items = [];

    switch (role) {
      case UserRole.citizen:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Safety Home'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
        ];
        break;
      case UserRole.technician:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.build_rounded), label: 'Work Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.sync_rounded), label: 'Offline Sync'),
        ];
        break;
      case UserRole.engineer:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Fleet Health'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'AI Anomaly'),
        ];
        break;
      case UserRole.authority:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Zone Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.priority_high_rounded), label: 'Escalations'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Audit Logs'),
        ];
        break;
      case UserRole.admin:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Platform'),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow_rounded), label: 'Demo Control'),
          BottomNavigationBarItem(icon: Icon(Icons.tune_rounded), label: 'Settings'),
        ];
        break;
    }

    return BottomNavigationBar(
      currentIndex: _currentIndex.clamp(0, items.length - 1),
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

  void _showRoleSwitchModal(BuildContext context, AuthService auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demo Role Switcher',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select any of the 5 supported roles to test role-based UI and access control:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ...UserRole.values.map((r) {
                final isCurrent = r == auth.currentRole;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.roleColor.withOpacity(0.15),
                    child: Icon(r.icon, color: r.roleColor, size: 20),
                  ),
                  title: Text(
                    r.displayName,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? r.roleColor : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text('Role ID: ${r.id}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  trailing: isCurrent ? Icon(Icons.check_circle, color: r.roleColor, size: 20) : null,
                  onTap: () {
                    auth.quickDemoLogin(r);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
