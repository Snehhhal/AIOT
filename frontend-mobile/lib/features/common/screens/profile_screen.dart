import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final locationService = Provider.of<LocationService>(context);
    final user = auth.currentUser;
    final role = auth.currentRole;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Badge Card
          Card(
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: role.roleColor.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: role.roleColor.withValues(alpha: 0.2),
                    child: Icon(role.icon, size: 36, color: role.roleColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User Name',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'user@poleguard.internal',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: role.roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role.displayName.toUpperCase(),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: role.roleColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // User Preferences & Operations
          const Text('Account & Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppTheme.infoColor),
                  title: const Text('App Language'),
                  subtitle: Text(auth.currentLanguage == AppLanguage.en ? 'English' : (auth.currentLanguage == AppLanguage.hi ? 'हिंदी' : 'मराठी')),
                  trailing: DropdownButton<AppLanguage>(
                    value: auth.currentLanguage,
                    underline: const SizedBox(),
                    dropdownColor: AppTheme.surfaceDark,
                    items: const [
                      DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
                      DropdownMenuItem(value: AppLanguage.hi, child: Text('हिंदी')),
                      DropdownMenuItem(value: AppLanguage.mr, child: Text('मराठी')),
                    ],
                    onChanged: (l) {
                      if (l != null) auth.setLanguage(l);
                    },
                  ),
                ),
                const Divider(color: AppTheme.borderDark, height: 1),
                ListTile(
                  leading: Icon(
                    locationService.hasPosition ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                    color: locationService.hasPosition ? AppTheme.safeColor : AppTheme.warningColor,
                  ),
                  title: const Text('GPS Hardware Location'),
                  subtitle: Text(
                    locationService.locationSourceLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Fetch Live GPS',
                    onPressed: () => locationService.fetchDeviceLocation(),
                  ),
                ),
                const Divider(color: AppTheme.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.location_city_rounded, color: AppTheme.safeColor),
                  title: const Text('Assigned Municipal Zone'),
                  subtitle: Text(user?.zone ?? 'Unassigned Municipal Zone'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Platform Technical Metadata
          const Text('Platform Diagnostics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMetaRow('System Version', 'PoleGuard v2.4 (Phase 11 Production)'),
                  const Divider(color: AppTheme.borderDark),
                  _buildMetaRow('Backend API', 'FastAPI 0.111 / SQLite / PostgreSQL'),
                  const Divider(color: AppTheme.borderDark),
                  _buildMetaRow('AI / ML Inference', 'Random Forest + YOLOv8 CV Detection'),
                  const Divider(color: AppTheme.borderDark),
                  _buildMetaRow('RAG Safety Store', 'ChromaDB Vector Store (CEA 2010 Regulations)'),
                  const Divider(color: AppTheme.borderDark),
                  _buildMetaRow('Hardware Status', 'MOCK IoT Telemetry Stream (ESP32 Ready)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cardDark,
              foregroundColor: AppTheme.emergencyColor,
              side: const BorderSide(color: AppTheme.emergencyColor),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () {
              auth.logout();
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
