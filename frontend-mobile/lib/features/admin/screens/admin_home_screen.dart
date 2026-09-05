import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final poleProvider = Provider.of<PoleProvider>(context);
    final targetPole = poleProvider.poles.isNotEmpty
        ? poleProvider.poles.firstWhere((p) => p.id == 'P-001', orElse: () => poleProvider.poles.first)
        : null;

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
                    auth.currentUser?.name ?? 'Administrator',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Text('Platform Root Configuration & System Health', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.emergencyColor, size: 32),
            ],
          ),
          const SizedBox(height: 16),

          // System Health Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INFRASTRUCTURE STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  _buildHealthItem('FastAPI Ingestion Engine', 'ONLINE (Port 8000)', AppTheme.safeColor),
                  _buildHealthItem('PostgreSQL Persistence', 'CONNECTED', AppTheme.safeColor),
                  _buildHealthItem('AI / CV Inference Service', 'READY (YOLOv8 + Scikit)', AppTheme.safeColor),
                  _buildHealthItem('ChromaDB Safety Vector Store', 'INITIALIZED (CEA 2010)', AppTheme.safeColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Demo Control Panel (Section 42 & 43 - Crucial for Viva & Judges)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.play_circle_filled_rounded, color: AppTheme.infoColor),
                        SizedBox(width: 8),
                        Text(
                          'Judge Demo Control Center',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.infoColor),
                        ),
                      ],
                    ),
                    if (targetPole != null)
                      StatusBadge(tier: targetPole.riskTier, isCompact: true),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Instantly trigger simulated fault scenarios on Pole P-001. All roles (Citizen, Tech, Engineer, Authority) react in real time.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (targetPole != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PoleDetailScreen(poleId: targetPole.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Target: ${targetPole.id} (${targetPole.status})',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(width: 4),
                              const Icon(Icons.open_in_new_rounded, size: 12, color: AppTheme.infoColor),
                            ],
                          ),
                          Text('Leak: ${targetPole.leakageCurrent.toStringAsFixed(1)}mA | Risk: ${targetPole.riskScore}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildScenarioButton(context, '1. Normal Steady (Safe)', Colors.green, () {
                      poleProvider.triggerScenario('P-001', 'NORMAL');
                      _showDemoSnackBar(context, 'Simulated Normal Steady on P-001 (Safe, 1.5mA).');
                    }),
                    _buildScenarioButton(context, '2. Leakage Spike (>30mA)', Colors.amber, () {
                      poleProvider.triggerScenario('P-001', 'LEAKAGE');
                      _showDemoSnackBar(context, 'Simulated Insulation Breakdown (36.5mA) on P-001.');
                    }),
                    _buildScenarioButton(context, '3. Leakage + Monsoon Rain', Colors.orange, () {
                      poleProvider.triggerScenario('P-001', 'LEAKAGE_RAIN');
                      _showDemoSnackBar(context, 'Simulated Leakage in Heavy Rain on P-001.');
                    }),
                    _buildScenarioButton(context, '4. CV: Human Proximity', Colors.purple, () {
                      poleProvider.triggerScenario('P-001', 'HUMAN_PROXIMITY');
                      _showDemoSnackBar(context, 'YOLO detected human within 1.2m of wet energized pole.');
                    }),
                    _buildScenarioButton(context, '5. FULL EMERGENCY', Colors.red, () {
                      poleProvider.triggerScenario('P-001', 'FULL_EMERGENCY');
                      _showDemoSnackBar(context, 'EMERGENCY: Leakage + Rain + Human + Waterlogged!');
                    }),
                    _buildScenarioButton(context, '🔄 Reset / Reload Fleet', Colors.blueGrey, () {
                      poleProvider.loadPoles();
                      _showDemoSnackBar(context, 'Reloaded pole fleet from backend database.');
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Admin Settings
          const Text(
            'Safety Threshold Management',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildThresholdRow('Max Touch Leakage (Danger)', '30.0 mA (IEC 60479)'),
                  const Divider(color: AppTheme.borderDark),
                  _buildThresholdRow('Max Allowable Pole Tilt', '15.0 Degrees'),
                  const Divider(color: AppTheme.borderDark),
                  _buildThresholdRow('Technician Response Timeout', '15 Minutes'),
                  const Divider(color: AppTheme.borderDark),
                  _buildThresholdRow('Authority Escalation Level', 'Level 2 Direct Notification'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHealthItem(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildThresholdRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.infoColor)),
      ],
    );
  }

  Widget _buildScenarioButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.8)),
        elevation: 0,
        minimumSize: const Size(140, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showDemoSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.surfaceDark),
    );
  }
}
