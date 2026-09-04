import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pole_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';

class AuthorityHomeScreen extends StatelessWidget {
  const AuthorityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final poleProvider = Provider.of<PoleProvider>(context);
    final hasEmergency = poleProvider.emergencyCount > 0;
    final overallTier = hasEmergency
        ? RiskTier.emergency
        : (poleProvider.warningCount > 0 ? RiskTier.warning : RiskTier.safe);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.currentUser?.name ?? 'Municipal Authority',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Text('Disaster Management & Public Safety Oversight', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              const Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6), size: 32),
            ],
          ),
          const SizedBox(height: 16),

          // Municipal Area Risk Heatmap Summary
          Card(
            color: AppTheme.surfaceDark,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('METROPOLITAN AREA SAFETY INDEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                      StatusBadge(tier: overallTier, isCompact: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (poleProvider.poles.isNotEmpty)
                    ...poleProvider.poles.map((p) => Column(
                          children: [
                            _buildZoneRow(
                              '${p.id} (${p.locationName})',
                              p.status,
                              _getTierColor(p.riskTier),
                              'Leakage: ${p.leakageCurrent.toStringAsFixed(1)}mA • Risk: ${p.riskScore}/100',
                            ),
                            if (p != poleProvider.poles.last) const Divider(color: AppTheme.borderDark),
                          ],
                        ))
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Loading zone risk metrics...', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Escalated Incidents (Technician Non-Response) - Section 26 & 27
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Escalated Incidents (Overdue Action)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (hasEmergency ? AppTheme.emergencyColor : AppTheme.safeColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasEmergency ? '${poleProvider.emergencyCount} ESCALATION' : '0 ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasEmergency ? AppTheme.emergencyColor : AppTheme.safeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasEmergency)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.emergencyColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ESCALATION #ESC-892', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emergencyColor)),
                        Text('18 mins overdue', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Critical leakage incident with waterlogging. Lineman acknowledgement timeout (>15 min). Direct authority intervention requested.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Call Dispatch', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Calling Emergency Dispatch Center...')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emergencyColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(40),
                            ),
                            icon: const Icon(Icons.power_settings_new, size: 16),
                            label: const Text('Order Cutoff', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Grid Isolation Relay Tripped. Substation notified.'),
                                  backgroundColor: AppTheme.emergencyColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user_rounded, color: AppTheme.safeColor, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No overdue incident escalations. All field activities within service SLAs.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Area Broadcast Emergency Warning Card
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceDark,
                child: Icon(Icons.cell_tower, color: AppTheme.warningColor),
              ),
              title: const Text('Emergency Area Alert Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Broadcast geo-fenced safety alert to citizens near dangerous poles.', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geo-fenced push alert dispatched to citizen mobile devices in Sector 4.'),
                    backgroundColor: AppTheme.warningColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Color _getTierColor(RiskTier tier) {
    switch (tier) {
      case RiskTier.emergency:
        return AppTheme.emergencyColor;
      case RiskTier.critical:
        return AppTheme.dangerColor;
      case RiskTier.warning:
        return AppTheme.warningColor;
      case RiskTier.safe:
        return AppTheme.safeColor;
    }
  }

  static Widget _buildZoneRow(String zone, String status, Color color, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
