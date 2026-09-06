import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/pole_provider.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class AuthorityZonesScreen extends StatelessWidget {
  const AuthorityZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final poleProvider = Provider.of<PoleProvider>(context);
    final zones = poleProvider.poles
        .map((p) => p.zone)
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metropolitan Risk Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: zones.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_rounded, size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'No Municipal Zones Registered',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'No registered poles found in the database. Discovered or registered poles will appear here grouped by municipal zone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: zones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final zone = zones[index];
                final zonePoles = poleProvider.poles.where((p) => p.zone == zone).toList();
                final hasEmergency = zonePoles.any((p) => p.riskTier == RiskTier.emergency || p.riskTier == RiskTier.critical);

          return Card(
            color: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: hasEmergency ? AppTheme.emergencyColor : AppTheme.safeColor, width: hasEmergency ? 1.5 : 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(zone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (hasEmergency ? AppTheme.emergencyColor : AppTheme.safeColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasEmergency ? 'HIGH RISK' : 'STABLE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasEmergency ? AppTheme.emergencyColor : AppTheme.safeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${zonePoles.length} Monitored Distribution Poles • Real-time IoT Ingestion Active',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Divider(color: AppTheme.borderDark, height: 20),
                  ...zonePoles.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: p.riskTier.color.withValues(alpha: 0.2),
                      child: Icon(p.riskTier.icon, size: 14, color: p.riskTier.color),
                    ),
                    title: Text('${p.id} — ${p.locationName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('Leakage: ${p.leakageCurrent.toStringAsFixed(1)}mA | Status: ${p.status}', style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: p.id)));
                    },
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
