import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final poleProvider = Provider.of<PoleProvider>(context);
    final loc = AppLocalizations(auth.currentLanguage);
    final nearestPole = poleProvider.selectedPole;

    final riskTier = nearestPole?.riskTier ?? RiskTier.safe;
    final isDanger = riskTier == RiskTier.emergency || riskTier == RiskTier.critical;
    final statusColor = riskTier.color;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${auth.currentUser?.name ?? "Citizen"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppTheme.infoColor),
                      const SizedBox(width: 4),
                      Text(
                        'Near ${nearestPole?.name ?? "FC Road"} • GPS Active',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              DropdownButton<AppLanguage>(
                value: auth.currentLanguage,
                underline: const SizedBox(),
                dropdownColor: AppTheme.surfaceDark,
                items: const [
                  DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
                  DropdownMenuItem(value: AppLanguage.hi, child: Text('हिंदी')),
                  DropdownMenuItem(value: AppLanguage.mr, child: Text('मराठी')),
                ],
                onChanged: (lang) {
                  if (lang != null) auth.setLanguage(lang);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary Safety Indicator Card (Bound to Live Telemetry)
          Card(
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: statusColor, width: isDanger ? 2.5 : 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NEAREST POLE: ${nearestPole?.id ?? "P-001"} (15m)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      StatusBadge(tier: riskTier),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: statusColor.withOpacity(0.15),
                    child: Icon(
                      riskTier.icon,
                      color: statusColor,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isDanger ? loc.tr('danger_title') : (riskTier == RiskTier.warning ? loc.tr('warning_title') : loc.tr('safe_title')),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDanger ? loc.tr('danger_desc') : (riskTier == RiskTier.warning ? loc.tr('warning_desc') : loc.tr('safe_desc')),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (nearestPole != null && nearestPole.rain)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, size: 14, color: AppTheme.infoColor),
                          SizedBox(width: 4),
                          Text('Wet Ground Warning: Rain Detected Near Base', style: TextStyle(fontSize: 11, color: AppTheme.infoColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Button: REPORT HAZARD
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            icon: const Icon(Icons.camera_alt_rounded, size: 24),
            label: Text(
              loc.tr('report_hazard'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening Camera for Hazard Report (Phase 2 Integration)'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Emergency SOS Helpline Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.emergencyColor, width: 2),
              foregroundColor: AppTheme.emergencyColor,
            ),
            icon: const Icon(Icons.phone_in_talk_rounded),
            label: Text(
              loc.tr('sos_emergency'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connecting to Emergency Helpline: 112')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Safety Guidelines Card
          const Text(
            'Safety Guidelines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTipRow(Icons.water_drop, 'Never touch electric poles standing in water or during heavy rains.'),
                  const Divider(color: AppTheme.borderDark),
                  _buildTipRow(Icons.social_distance, 'Keep at least a 5-meter safety distance from sparking poles.'),
                  const Divider(color: AppTheme.borderDark),
                  _buildTipRow(Icons.report, 'Immediately report loose overhead wires or visible tilted poles.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
