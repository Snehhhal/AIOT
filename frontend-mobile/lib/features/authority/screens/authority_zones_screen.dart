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
    final zones = ['Sector 1 (Shivajinagar)', 'Sector 2 (Railway Circle)', 'Sector 3 (Kothrud)', 'Sector 4 (Pune Cantonment)'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metropolitan Risk Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: zones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final zone = zones[index];
          final sectorKey = 'Sector ${index + 1}';
          final zonePoles = poleProvider.poles.where((p) => p.zone == sectorKey).toList();
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
                          color: (hasEmergency ? AppTheme.emergencyColor : AppTheme.safeColor).withOpacity(0.15),
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
                      backgroundColor: p.riskTier.color.withOpacity(0.2),
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
