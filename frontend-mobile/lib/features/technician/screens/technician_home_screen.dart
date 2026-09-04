import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../common/widgets/status_badge.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  String _workStatus = 'ASSIGNED';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technician Header Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.currentUser?.name ?? 'Technician On Duty',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Sub-Div Sector 4 • ID #LINEMAN-14',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.assignment_late_rounded, size: 16, color: AppTheme.warningColor),
                    SizedBox(width: 4),
                    Text('1 Urgent Task', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Offline Actions Outbox Indicator (Section 29)
          if (auth.isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppTheme.warningColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '3 offline actions in local outbox queue. Will auto-sync when network returns.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // Active Critical Incident Card (Section 7)
          Card(
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.emergencyColor, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'POLE: P-001',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const StatusBadge(tier: RiskTier.emergency),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'MG Road Junction, Opp. Metro Pillar 42',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 24),

                  // Sensor Matrix Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Leakage Current', '48.5 mA', AppTheme.emergencyColor),
                      _buildMetric('Surface Voltage', '74.2 V', AppTheme.dangerColor),
                      _buildMetric('Rain Sensor', 'ACTIVE (96%)', AppTheme.infoColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric('Human Proximity', 'DETECTED (1.2m)', AppTheme.emergencyColor),
                      _buildMetric('Standing Water', 'DETECTED (Base)', AppTheme.dangerColor),
                      _buildMetric('Risk Score', '94 / 100', AppTheme.emergencyColor),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Decision Engine Explanation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppTheme.infoColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'WHY? Critical leakage current (>30mA) combined with rain, standing water and pedestrian proximity poses imminent shock hazard.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Work Order Status
                  Row(
                    children: [
                      const Text('Work Order Status: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _workStatus,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.infoColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (Section 7)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildActionButton('ACKNOWLEDGE', Icons.check_circle_outline, () {
                        setState(() => _workStatus = 'ACKNOWLEDGED');
                      }),
                      _buildActionButton('START INSPECT', Icons.play_arrow_rounded, () {
                        setState(() => _workStatus = 'UNDER INSPECTION');
                      }),
                      _buildActionButton('REPAIR IN PROGRESS', Icons.handyman_rounded, () {
                        setState(() => _workStatus = 'REPAIR IN PROGRESS');
                      }),
                      _buildActionButton('UPLOAD PHOTO', Icons.camera_alt_outlined, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Camera opened for evidence upload.')),
                        );
                      }),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safeColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 44),
                        ),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: const Text('MARK RESOLVED'),
                        onPressed: () {
                          setState(() => _workStatus = 'RESOLVED');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Incident P-001 marked RESOLVED. Supervisor notified.'),
                              backgroundColor: AppTheme.safeColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Safety SOP Chatbot Card
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceDark,
                child: Icon(Icons.smart_toy_outlined, color: AppTheme.infoColor),
              ),
              title: const Text('Field Safety SOP Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Ask isolation, earthing, or PPE rules before touching pole equipment.', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('RAG Safety Chatbot (Phase 11 Integration)')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMetric(String label, String val, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valColor),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(130, 42),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
    );
  }
}
