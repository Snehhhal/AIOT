import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pole_model.dart';
import '../../../models/sensor_history_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';
import '../widgets/sensor_trend_chart.dart';

class PoleDetailScreen extends StatefulWidget {
  final String poleId;

  const PoleDetailScreen({super.key, required this.poleId});

  @override
  State<PoleDetailScreen> createState() => _PoleDetailScreenState();
}

class _PoleDetailScreenState extends State<PoleDetailScreen> {
  bool _isLoadingHistory = false;
  List<SensorHistoryPoint> _historyPoints = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    setState(() => _isLoadingHistory = true);
    final poleProvider = Provider.of<PoleProvider>(context, listen: false);
    final points = await poleProvider.fetchPoleHistory(widget.poleId, forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _historyPoints = points;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final poleProvider = Provider.of<PoleProvider>(context);
    final auth = Provider.of<AuthService>(context);
    final pole = poleProvider.poles.firstWhere(
      (p) => p.id == widget.poleId,
      orElse: () => poleProvider.selectedPole ?? _createFallback(widget.poleId),
    );

    // Keep history in sync with provider cache if new points arrived
    final cached = poleProvider.historyCache[widget.poleId];
    final displayPoints = (cached != null && cached.isNotEmpty) ? cached : _historyPoints;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Pole ${widget.poleId} Telemetry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Telemetry',
            onPressed: () => _loadHistory(forceRefresh: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pole Asset Information Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pole.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ' • ',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      StatusBadge(tier: pole.riskTier),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip(
                        pole.isOnline ? '🟢 ONLINE' : '🔴 OFFLINE',
                        pole.isOnline ? AppTheme.safeColor : AppTheme.dangerColor,
                      ),
                      const SizedBox(width: 8),
                      _buildChip('GPS: , ', AppTheme.infoColor),
                      const SizedBox(width: 8),
                      _buildChip(pole.serialNumber ?? 'SN: ', AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Sensor Matrix (Section 4 Telemetry)
            Row(
              children: [
                Expanded(
                  child: _buildSensorGauge(
                    'Leakage Current',
                    ' mA',
                    pole.leakageCurrent >= 30.0
                        ? AppTheme.emergencyColor
                        : (pole.leakageCurrent >= 10.0 ? AppTheme.warningColor : AppTheme.safeColor),
                    Icons.flash_on_rounded,
                    sub: 'Threshold: 30mA',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSensorGauge(
                    'Touch Voltage',
                    ' V',
                    pole.voltage >= 50.0 ? AppTheme.dangerColor : AppTheme.safeColor,
                    Icons.bolt_rounded,
                    sub: 'Nominal: 230V',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSensorGauge(
                    'Rain & Moisture',
                    pole.rain ? 'ACTIVE (Rain)' : 'DRY',
                    pole.rain ? AppTheme.infoColor : AppTheme.textSecondary,
                    Icons.water_drop_rounded,
                    sub: 'Humidity: %',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSensorGauge(
                    'Pole Health',
                    ' / 100',
                    pole.healthScore < 65
                        ? AppTheme.emergencyColor
                        : (pole.healthScore < 80 ? AppTheme.warningColor : AppTheme.safeColor),
                    Icons.health_and_safety_rounded,
                    sub: 'Risk Index: ',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Interactive Sensor Trend Chart (Phase 5 Feature)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Historical Telemetry & Anomaly Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingHistory && displayPoints.isEmpty)
              Container(
                height: 220,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: AppTheme.infoColor),
              )
            else
              SensorTrendChart(points: displayPoints),
            const SizedBox(height: 20),

            // Deterministic Decision Engine Analysis Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'DECISION ENGINE SAFETY ASSESSMENT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          'CRI: /100',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: _getTierColor(pole.riskTier),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getDecisionExplanation(pole),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                    ),
                    const Divider(color: AppTheme.borderDark, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFactItem('Human Proximity', pole.humanDetected ? 'DETECTED' : 'CLEAR', pole.humanDetected ? AppTheme.emergencyColor : AppTheme.safeColor),
                        _buildFactItem('Standing Water', pole.standingWaterDetected ? 'DETECTED' : 'CLEAR', pole.standingWaterDetected ? AppTheme.dangerColor : AppTheme.safeColor),
                        _buildFactItem('Weather Factor', pole.rain ? '1.35x Multiplier' : '1.0x Normal', pole.rain ? AppTheme.warningColor : AppTheme.safeColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 24-Hour Incident & Anomaly Timeline
            const Text(
              'Incident & Breach Log (Last 24 Hours)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            _buildTimelineItem(
              'Insulation Leakage Anomaly Spike',
              'mA recorded. Exceeded 30mA let-go safety threshold.',
              pole.riskTier == RiskTier.emergency ? 'CRITICAL BREACH' : 'LOGGED',
              pole.riskTier == RiskTier.emergency ? AppTheme.emergencyColor : AppTheme.warningColor,
            ),
            if (pole.rain)
              _buildTimelineItem(
                'Monsoon Ground Saturation',
                'Rain sensor activated base grounding impedance reduction.',
                'ENVIRONMENTAL',
                AppTheme.infoColor,
              ),
            _buildTimelineItem(
              'Routine Telemetry Heartbeat',
              'All sensor channels streaming nominally at 1 packet/sec.',
              'INFO',
              AppTheme.safeColor,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (auth.currentRole == UserRole.technician)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.handyman_rounded),
                  label: const Text('LOG ON-SITE FIELD INSPECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Field inspection started for .')),
                    );
                  },
                ),
              ),
            if (auth.currentRole == UserRole.authority)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emergencyColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('EMERGENCY FEEDER ISOLATION CUTOFF', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Grid Isolation Relay Tripped for Pole . Substation notified.'),
                        backgroundColor: AppTheme.emergencyColor,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  static Widget _buildSensorGauge(String title, String value, Color color, IconData icon, {required String sub}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  static Widget _buildFactItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  static Widget _buildTimelineItem(String title, String desc, String tag, Color tagColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
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
      return 'CRITICAL HAZARD: Leakage current (mA) exceeds lethal threshold (30mA)'
          ''
          '. Grid relay trip recommended.';
    } else if (pole.riskTier == RiskTier.critical) {
      return 'HIGH RISK: Leakage current (mA) indicates advanced dielectric insulation failure. Technician inspection required.';
    } else if (pole.riskTier == RiskTier.warning) {
      return 'ADVISORY: Minor current elevation (mA). Predictive maintenance suggested within 48 hours.';
    } else {
      return 'NOMINAL: Telemetry parameters within normal tolerances. Grounding integrity verified.';
    }
  }

  static PoleModel _createFallback(String id) {
    return PoleModel(
      id: id,
      name: 'Electric Pole ',
      location: 'Urban Distribution Node',
      latitude: 18.5204,
      longitude: 73.8567,
      zone: 'Sector 4',
      status: 'CRITICAL',
      leakageCurrent: 48.5,
      voltage: 74.2,
      riskTier: RiskTier.emergency,
    );
  }
}
