import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localizations.dart';
import '../../../services/auth_service.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final loc = AppLocalizations(auth.currentLanguage);

    final roleData = [
      _RoleCardData(
        role: UserRole.citizen,
        title: loc.tr('role_citizen_title'),
        tagline: loc.tr('role_citizen_tagline'),
        badge: 'PUBLIC ACCESS',
        badgeColor: AppTheme.successColor,
        icon: Icons.person_rounded,
        color: AppTheme.successColor,
      ),
      _RoleCardData(
        role: UserRole.technician,
        title: loc.tr('role_technician_title'),
        tagline: loc.tr('role_technician_tagline'),
        badge: 'FIELD STAFF',
        badgeColor: AppTheme.warningColor,
        icon: Icons.handyman_rounded,
        color: AppTheme.warningColor,
      ),
      _RoleCardData(
        role: UserRole.engineer,
        title: loc.tr('role_engineer_title'),
        tagline: loc.tr('role_engineer_tagline'),
        badge: 'SUPERVISORY',
        badgeColor: AppTheme.infoColor,
        icon: Icons.engineering_rounded,
        color: AppTheme.infoColor,
      ),
      _RoleCardData(
        role: UserRole.authority,
        title: loc.tr('role_authority_title'),
        tagline: loc.tr('role_authority_tagline'),
        badge: 'MUNICIPAL',
        badgeColor: Colors.purpleAccent,
        icon: Icons.account_balance_rounded,
        color: Colors.purpleAccent,
      ),
      _RoleCardData(
        role: UserRole.admin,
        title: loc.tr('role_admin_title'),
        tagline: loc.tr('role_admin_tagline'),
        badge: 'SYSTEM ADMIN',
        badgeColor: AppTheme.dangerColor,
        icon: Icons.admin_panel_settings_rounded,
        color: AppTheme.dangerColor,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.infoColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              loc.tr('select_user_type'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Language Dropdown Selector
          PopupMenuButton<AppLanguage>(
            tooltip: loc.tr('select_language'),
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: AppTheme.surfaceDark,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(auth.currentLanguage.flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    auth.currentLanguage.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white70),
                ],
              ),
            ),
            onSelected: (AppLanguage selected) {
              auth.setLanguage(selected);
            },
            itemBuilder: (context) => AppLanguage.values.map((lang) {
              final isSelected = lang == auth.currentLanguage;
              return PopupMenuItem<AppLanguage>(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Text(
                      lang.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.infoColor : Colors.white,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded, size: 18, color: AppTheme.infoColor),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Text(
                loc.tr('app_title'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.tr('select_role_desc'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // 5 Large Role Cards
              ...roleData.map((data) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      auth.setSelectedRole(data.role);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: data.color.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: data.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: data.color.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Icon(data.icon, color: data.color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: data.color,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                                  data.tagline,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward_ios_rounded, color: data.color.withValues(alpha: 0.8), size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
              // Emergency Helpline Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: AppTheme.dangerColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${loc.tr('sos_emergency')} • Electricity Emergency Helpline 1912',
                        style: const TextStyle(
                          color: AppTheme.dangerColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
  final String tagline;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final Color color;

  const _RoleCardData({
    required this.role,
    required this.title,
    required this.tagline,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.color,
  });
}

