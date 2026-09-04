import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pole_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/pole_provider.dart';
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
    final poleProvider = Provider.of<PoleProvider>(context);
    final selectedPole = poleProvider.selectedPole;

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
                  color: (poleProvider.emergencyCount > 0
                          ? AppTheme.emergencyColor
                          : AppTheme.safeColor)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: poleProvider.emergencyCount > 0
                        ? AppTheme.emergencyColor
                        : AppTheme.safeColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      poleProvider.emergencyCount > 0
                          ? Icons.assignment_late_rounded
                          : Icons.task_alt_rounded,
                      size: 16,
                      color: poleProvider.emergencyCount > 0
                          ? AppTheme.emergencyColor
                          : AppTheme.safeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${poleProvider.emergencyCount} Urgent Task${poleProvider.emergencyCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: poleProvider.emergencyCount > 0
                            ? AppTheme.emergencyColor
                            : AppTheme.safeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pole Selection Selector Bar
          if (poleProvider.poles.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: poleProvider.poles.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final p = poleProvider.poles[index];
                  final isSelected = selectedPole?.id == p.id;
                  final color = _getTierColor(p.riskTier);

                  return ChoiceChip(
                    label: Text(p.id, style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    )),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: AppTheme.cardDark,
                    side: BorderSide(color: color.withOpacity(isSelected ? 1.0 : 0.4)),
                    onSelected: (selected) {
                      if (selected) {
                        poleProvider.selectPole(p.id);
                      }
                    },
                  );
                },
              ),
            ),

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
                      'Local outbox queue active. Telemetry will auto-sync when network returns.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // Active Incident Card (Section 7)
          if (selectedPole != null)
            Card(
              color: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _getTierColor(selectedPole.riskTier),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'POLE: ${selectedPole.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        StatusBadge(tier: selectedPole.riskTier),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedPole.locationName,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const Divider(color: AppTheme.borderDark, height: 24),

                    // Sensor Matrix Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric(
                          'Leakage Current',
                          '${selectedPole.leakageCurrent.toStringAsFixed(1)} mA',
                          selectedPole.leakageCurrent > 30.0
                              ? AppTheme.emergencyColor
                              : (selectedPole.leakageCurrent > 10.0
                                  ? AppTheme.warningColor
                                  : AppTheme.safeColor),
                        ),
                        _buildMetric(
                          'Surface Voltage',
                          '${selectedPole.voltage.toStringAsFixed(1)} V',
                          selectedPole.voltage > 50.0
                              ? AppTheme.dangerColor
                              : AppTheme.safeColor,
                        ),
                        _buildMetric(
                          'Rain Sensor',
                          selectedPole.rain ? 'ACTIVE' : 'DRY',
                          selectedPole.rain ? AppTheme.infoColor : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric(
                          'Human Proximity',
                          selectedPole.humanDetected ? 'DETECTED' : 'CLEAR',
                          selectedPole.humanDetected
                              ? AppTheme.emergencyColor
                              : AppTheme.safeColor,
                        ),
                        _buildMetric(
                          'Standing Water',
                          selectedPole.standingWaterDetected ? 'DETECTED' : 'CLEAR',
                          selectedPole.standingWaterDetected
                              ? AppTheme.dangerColor
                              : AppTheme.safeColor,
                        ),
                        _buildMetric(
                          'Risk Score',
                          '${selectedPole.riskScore} / 100',
                          _getTierColor(selectedPole.riskTier),
                        ),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppTheme.infoColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getDecisionExplanation(selectedPole),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
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
                              SnackBar(
                                content: Text('Incident ${selectedPole.id} marked RESOLVED. Supervisor notified.'),
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
              onTap: () {
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

  static String _getDecisionExplanation(PoleModel pole) {
    if (pole.riskTier == RiskTier.emergency) {
      return 'EMERGENCY: Leakage current (${pole.leakageCurrent}mA) exceeds safety threshold (30mA)'
          '${pole.rain ? ' in wet conditions' : ''}'
          '${pole.humanDetected ? ' with human detected in danger zone' : ''}. Immediate isolation required.';
    } else if (pole.riskTier == RiskTier.critical) {
      return 'CRITICAL: High leakage current (${pole.leakageCurrent}mA). Insulation degradation detected. Requires prompt technician inspection.';
    } else if (pole.riskTier == RiskTier.warning) {
      return 'WARNING: Elevated readings. Environmental factors or early insulation fatigue detected. Scheduled maintenance advised.';
    } else {
      return 'NORMAL: All sensor telemetry within standard nominal bounds (Leakage < 5mA, tilt nominal). Pole safe.';
    }
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
