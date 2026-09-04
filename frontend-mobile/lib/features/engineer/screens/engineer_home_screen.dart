import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../common/widgets/status_badge.dart';

class EngineerHomeScreen extends StatelessWidget {
  const EngineerHomeScreen({super.key});

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
                    auth.currentUser?.name ?? 'Supervising Engineer',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Text('Sub-Division Technical Operations Control', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              const Icon(Icons.engineering_rounded, color: AppTheme.infoColor, size: 32),
            ],
          ),
          const SizedBox(height: 16),

          // Fleet Health Overview Cards
          Row(
            children: [
              _buildSummaryCard('Fleet Poles', '42', AppTheme.infoColor, Icons.electrical_services_rounded),
              const SizedBox(width: 8),
              _buildSummaryCard('Emergency', '1', AppTheme.emergencyColor, Icons.warning_rounded),
              const SizedBox(width: 8),
              _buildSummaryCard('Avg Health', '86%', AppTheme.safeColor, Icons.health_and_safety_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Priority Critical Incidents List
          const Text(
            'Active Distribution Hazards',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pole P-001 • Sector 4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('48.5mA leakage • Wet Ground • Human 1.2m', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const StatusBadge(tier: RiskTier.emergency, isCompact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Assigned: Lineman Kailas (#14)', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                        Text('Status: UNDER INSPECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                          icon: const Icon(Icons.alt_route_rounded, size: 16),
                          label: const Text('Reassign Tech', style: TextStyle(fontSize: 12)),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.safeColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(40),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve Work', style: TextStyle(fontSize: 12)),
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

          // AI Predictive Maintenance & Health Ranking
          const Text(
            'Pole Health & Maintenance Priorities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          _buildHealthRow('P-001', '58/100', 'High Priority', AppTheme.emergencyColor),
          _buildHealthRow('P-002', '76/100', 'Moderate Degradation', AppTheme.warningColor),
          _buildHealthRow('P-003', '94/100', 'Optimal Healthy', AppTheme.safeColor),
          _buildHealthRow('P-004', '98/100', 'Optimal Healthy', AppTheme.safeColor),
        ],
      ),
    );
  }

  static Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  static Widget _buildHealthRow(String poleId, String score, String desc, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(poleId.substring(2), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text('Pole $poleId', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Text(score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ),
    );
  }
}
