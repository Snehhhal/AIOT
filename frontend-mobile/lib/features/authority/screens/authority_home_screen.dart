import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../common/widgets/status_badge.dart';

class AuthorityHomeScreen extends StatelessWidget {
  const AuthorityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('METROPOLITAN AREA SAFETY INDEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                      StatusBadge(tier: RiskTier.warning, isCompact: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildZoneRow('Zone 1 (Kothrud/West)', 'SAFE', AppTheme.safeColor, '0 incidents'),
                  const Divider(color: AppTheme.borderDark),
                  _buildZoneRow('Zone 2 (FC Road/Central)', 'WARNING', AppTheme.warningColor, '2 insulation advisories'),
                  const Divider(color: AppTheme.borderDark),
                  _buildZoneRow('Zone 3 (Station Road/East)', 'EMERGENCY', AppTheme.emergencyColor, '1 active leak + waterlogged'),
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
                  color: AppTheme.emergencyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('1 ESCALATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emergencyColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                    'Incident P-001: Lineman acknowledgement timeout (>15 min). Escalated from Sub-Div Engineer to Commissioner Office.',
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
                          onPressed: () {},
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
                          icon: const Icon(Icons.emergency_share, size: 16),
                          label: const Text('Order Cutoff', style: TextStyle(fontSize: 12)),
                          onPressed: () {},
                        ),
                      ),
                    ],
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
              subtitle: const Text('Simulate geo-fenced safety warning push to registered citizen phones.', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulating geo-fenced emergency warning broadcast.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildZoneRow(String zone, String status, Color color, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
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
