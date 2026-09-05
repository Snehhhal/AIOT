import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    final roleData = [
      _RoleCardData(
        role: UserRole.citizen,
        title: 'Citizen',
        badge: 'OPEN ACCESS',
        badgeColor: AppTheme.successColor,
        description: 'Check nearby pole safety, report sparking or water hazards with camera photos, and access safety guidelines.',
        icon: Icons.person_rounded,
        color: AppTheme.successColor,
      ),
      _RoleCardData(
        role: UserRole.technician,
        title: 'Technician / Lineman',
        badge: 'STAFF AUTH REQUIRED',
        badgeColor: AppTheme.warningColor,
        description: 'Receive dispatched incidents, acknowledge hazards, record inspection notes, upload repair photos.',
        icon: Icons.handyman_rounded,
        color: AppTheme.warningColor,
      ),
      _RoleCardData(
        role: UserRole.engineer,
        title: 'Engineer / Supervisor',
        badge: 'STAFF AUTH REQUIRED',
        badgeColor: AppTheme.infoColor,
        description: 'Fleet-wide pole health ranking, sensor breach analytics, work order delegation, and AI prediction triage.',
        icon: Icons.engineering_rounded,
        color: AppTheme.infoColor,
      ),
      _RoleCardData(
        role: UserRole.authority,
        title: 'Municipal Authority',
        badge: 'EXECUTIVE CLEARANCE',
        badgeColor: Colors.purpleAccent,
        description: 'Metropolitan safety index, zone risk aggregation, emergency escalation monitoring, and power grid cutoffs.',
        icon: Icons.account_balance_rounded,
        color: Colors.purpleAccent,
      ),
      _RoleCardData(
        role: UserRole.admin,
        title: 'System Administrator',
        badge: 'ROOT PRIVILEGES',
        badgeColor: AppTheme.dangerColor,
        description: 'User access control, pole asset registry, immutable audit logs, and IoT simulation test controls.',
        icon: Icons.admin_panel_settings_rounded,
        color: AppTheme.dangerColor,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Select Your Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your role to sign in or register. Staff accounts require verified municipal authorization.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              ...roleData.map((data) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      auth.setSelectedRole(data.role);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: data.color.withValues(alpha: 0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: data.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(data.icon, color: data.color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      data.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: data.color,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: data.badgeColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: data.badgeColor.withValues(alpha: 0.4), width: 1),
                                      ),
                                      child: Text(
                                        data.badge,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: data.badgeColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: data.color.withValues(alpha: 0.7), size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCardData {
  final UserRole role;
  final String title;
  final String badge;
  final Color badgeColor;
  final String description;
  final IconData icon;
  final Color color;

  const _RoleCardData({
    required this.role,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.icon,
    required this.color,
  });
}
