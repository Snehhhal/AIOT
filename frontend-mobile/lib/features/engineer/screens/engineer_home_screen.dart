import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class EngineerHomeScreen extends StatelessWidget {
  const EngineerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final poleProvider = Provider.of<PoleProvider>(context);
    final criticalPoles = poleProvider.poles
        .where((p) => p.riskTier == RiskTier.emergency || p.riskTier == RiskTier.critical)
        .toList();

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
              _buildSummaryCard('Fleet Poles', '${poleProvider.totalCount}', AppTheme.infoColor, Icons.electrical_services_rounded),
              const SizedBox(width: 8),
              _buildSummaryCard(
                'Emergency',
                '${poleProvider.emergencyCount}',
                poleProvider.emergencyCount > 0 ? AppTheme.emergencyColor : AppTheme.safeColor,
                Icons.warning_rounded,
              ),
              const SizedBox(width: 8),
              _buildSummaryCard('Avg Health', '${poleProvider.averageHealth.toStringAsFixed(0)}%', AppTheme.safeColor, Icons.health_and_safety_rounded),
            ],
          ),
          const SizedBox(height: 20),

          // Priority Critical Incidents List
          const Text(
            'Active Distribution Hazards',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          if (criticalPoles.isNotEmpty)
            ...criticalPoles.map((pole) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: _getTierColor(pole.riskTier), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pole ${pole.id} • ${pole.locationName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  '${pole.leakageCurrent.toStringAsFixed(1)}mA leakage • ${pole.rain ? "Wet Ground" : "Dry"} • ${pole.humanDetected ? "Human in Proximity" : "No Human Nearby"}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            StatusBadge(tier: pole.riskTier, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Assigned: Duty Field Unit #14', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                              Text(
                                pole.riskTier == RiskTier.emergency ? 'STATUS: URGENT ESCALATION' : 'STATUS: DISPATCHED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: pole.riskTier == RiskTier.emergency ? AppTheme.emergencyColor : AppTheme.warningColor,
                                ),
                              ),
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
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Reassign technician request sent for ${pole.id}.')),
                                  );
                                },
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
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Work order approved for ${pole.id}.'), backgroundColor: AppTheme.safeColor),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.safeColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('All Poles Operating Safely', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text('No critical leakage incidents detected across monitored sectors.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
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
          ...poleProvider.poles.map((p) => _buildHealthRow(
                p.id,
                '${p.healthScore}/100',
                '${p.status} • Leakage: ${p.leakageCurrent.toStringAsFixed(1)}mA',
                _getTierColor(p.riskTier),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PoleDetailScreen(poleId: p.id),
                    ),
                  );
                },
              )),
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

  static Widget _buildHealthRow(String poleId, String score, String desc, Color color, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            poleId.length > 2 ? poleId.substring(2) : poleId,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Pole $poleId', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
