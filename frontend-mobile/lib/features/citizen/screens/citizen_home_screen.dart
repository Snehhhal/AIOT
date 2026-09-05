import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localizations.dart';
import '../../../models/pole_model.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';
import '../../monitoring/screens/pole_detail_screen.dart';
import 'citizen_chat_screen.dart';
import 'citizen_report_screen.dart';
import 'citizen_reports_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  List<PoleModel> _nearbyPoles = [];
  bool _isLoadingNearby = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationAndPoles();
    });
  }

  Future<void> _loadLocationAndPoles() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    if (!locationService.hasPosition) {
      await locationService.fetchDeviceLocation();
    }
    await _loadNearby();
  }

  Future<void> _loadNearby() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    setState(() => _isLoadingNearby = true);
    try {
      final poles = await ApiClient.getNearbyPoles(
        latitude: locationService.effectiveLatitude,
        longitude: locationService.effectiveLongitude,
        radiusKm: 15.0,
      );
      if (mounted) {
        setState(() {
          _nearbyPoles = poles;
          _isLoadingNearby = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingNearby = false);
    }
  }

  void _showSosDialog(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.emergencyColor, size: 28),
            SizedBox(width: 10),
            Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you see sparking, an electric shock hazard, or someone in danger, immediately maintain safe distance (at least 10m) and call emergency services.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emergencyColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.phone),
              label: const Text('Call 112 (National Emergency)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('National Disaster Helpline: Dial 112 from your phone.'),
                    backgroundColor: AppTheme.emergencyColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.warningColor),
                foregroundColor: AppTheme.warningColor,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Call 1912 (Electricity Helpline)', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Electricity Department Helpline: Dial 1912 from your phone.'),
                    backgroundColor: AppTheme.warningColor,
                  ),
                );
              },
            ),

          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final poleProvider = Provider.of<PoleProvider>(context);
    final locationService = Provider.of<LocationService>(context);
    final loc = AppLocalizations(auth.currentLanguage);

    final nearestPole = _nearbyPoles.isNotEmpty
        ? _nearbyPoles.first
        : (poleProvider.selectedPole ?? (poleProvider.poles.isNotEmpty ? poleProvider.poles.first : null));

    final riskTier = nearestPole?.riskTier ?? RiskTier.safe;
    final isDanger = riskTier == RiskTier.emergency || riskTier == RiskTier.critical;
    final statusColor = riskTier.color;

    return RefreshIndicator(
      onRefresh: () async {
        await poleProvider.loadPoles();
        await _loadLocationAndPoles();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Greeting & Language Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${auth.currentUser?.name.split(' ').first ?? "Citizen"} 👋',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stay safe around power infrastructure',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                // Language Dropdown
                PopupMenuButton<AppLanguage>(
                  tooltip: loc.tr('select_language'),
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: AppTheme.surfaceDark,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(auth.currentLanguage.flag, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 4),
                        Text(
                          auth.currentLanguage.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                      ],
                    ),
                  ),
                  onSelected: (AppLanguage selected) => auth.setLanguage(selected),
                  itemBuilder: (context) => AppLanguage.values.map((lang) {
                    final isSelected = lang == auth.currentLanguage;
                    return PopupMenuItem<AppLanguage>(
                      value: lang,
                      child: Row(
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Text(
                            lang.label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.infoColor : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Emergency SOS Button & Location Banner in Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  // Location Status Row
                  Row(
                    children: [
                      Icon(
                        locationService.hasPosition ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                        size: 16,
                        color: locationService.hasPosition ? AppTheme.safeColor : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationService.hasPosition
                              ? '${loc.tr('live_gps')}: ${locationService.effectiveLatitude?.toStringAsFixed(4)}, ${locationService.effectiveLongitude?.toStringAsFixed(4)}'
                              : loc.tr('location_permission_needed'),
                          style: TextStyle(
                            fontSize: 12,
                            color: locationService.hasPosition ? AppTheme.textPrimary : AppTheme.warningColor,
                            fontWeight: locationService.hasPosition ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!locationService.hasPosition)
                        TextButton(
                          onPressed: () {
                            if (locationService.permissionState == LocationPermissionState.permanentlyDenied) {
                              locationService.openAppSettings();
                            } else if (locationService.permissionState == LocationPermissionState.servicesDisabled) {
                              locationService.openLocationSettings();
                            } else {
                              locationService.fetchDeviceLocation().then((_) => _loadNearby());
                            }
                          },
                          child: Text(
                            loc.tr('grant_permission'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.infoColor),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textSecondary),
                          tooltip: loc.tr('refresh_location'),
                          onPressed: () => locationService.fetchDeviceLocation().then((_) => _loadNearby()),
                        ),
                    ],
                  ),
                  const Divider(color: AppTheme.borderDark, height: 16),
                  // Emergency SOS 112 Banner
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showSosDialog(context, loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.emergencyColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.phone_in_talk_rounded, color: AppTheme.emergencyColor, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'EMERGENCY SOS: Dial 112 / 1912',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.emergencyColor,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.emergencyColor, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Big Primary Status Card (Plain Language)
            Card(
              color: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: statusColor, width: isDanger ? 2.5 : 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          nearestPole != null
                              ? 'NEAREST POLE: ${nearestPole.id}'
                              : 'MONITORING AREA SAFETY',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        StatusBadge(tier: riskTier),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(
                        riskTier.icon,
                        color: statusColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isDanger
                          ? loc.tr('danger_title')
                          : (riskTier == RiskTier.warning ? loc.tr('warning_title') : loc.tr('safe_title')),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isDanger
                          ? loc.tr('danger_desc')
                          : (riskTier == RiskTier.warning ? loc.tr('warning_desc') : loc.tr('safe_desc')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    if (nearestPole != null && nearestPole.rain) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop, size: 14, color: AppTheme.infoColor),
                            SizedBox(width: 4),
                            Text(
                              'Wet Ground Warning: Rain Detected Near Pole Base',
                              style: TextStyle(fontSize: 11, color: AppTheme.infoColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Citizen Quick Actions Title
            const Text(
              'Citizen Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),

            // 2x2 Quick Actions Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _buildActionTile(
                  icon: Icons.add_a_photo_rounded,
                  iconColor: AppTheme.dangerColor,
                  title: loc.tr('action_report_pole'),
                  subtitle: loc.tr('action_report_pole_desc'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenReportScreen()),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppTheme.infoColor,
                  title: loc.tr('action_ai_assistant'),
                  subtitle: loc.tr('action_ai_assistant_desc'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenChatScreen()),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppTheme.warningColor,
                  title: loc.tr('action_my_reports'),
                  subtitle: loc.tr('action_my_reports_desc'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenReportsScreen()),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.electrical_services_rounded,
                  iconColor: AppTheme.safeColor,
                  title: loc.tr('action_nearby_poles'),
                  subtitle: '${_nearbyPoles.length} poles active',
                  onTap: () {
                    if (nearestPole != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: nearestPole.id)),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nearby Registered Poles List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Utility Poles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  onPressed: _loadNearby,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingNearby)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_nearbyPoles.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppTheme.infoColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No registered poles within 15km of current coordinates.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._nearbyPoles.map((p) {
                final distStr = p.distanceMeters != null
                    ? (p.distanceMeters! < 1000
                        ? '${p.distanceMeters!.round()}m'
                        : '${(p.distanceMeters! / 1000).toStringAsFixed(1)}km')
                    : 'Nearby';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: p.id)),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: p.riskTier.color.withValues(alpha: 0.15),
                      child: Icon(p.riskTier.icon, color: p.riskTier.color, size: 20),
                    ),
                    title: Text(
                      '${p.id} • ${p.locationName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${p.address ?? p.zone} • $distStr away',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(tier: p.riskTier, isCompact: true),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Safety Guidelines (Plain non-technical instructions)
            const Text(
              'Public Electrical Safety Rules',
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
                    _buildTipRow(Icons.water_drop_rounded, 'Never touch electric poles or walk near them in waterlogged areas during rain.'),
                    const Divider(color: AppTheme.borderDark),
                    _buildTipRow(Icons.social_distance_rounded, 'Keep at least a 5 to 10-meter safety distance from any buzzing, sparking, or smoking pole.'),
                    const Divider(color: AppTheme.borderDark),
                    _buildTipRow(Icons.report_problem_rounded, 'If a power line is down, treat it as live! Do not approach and dial 112 immediately.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

