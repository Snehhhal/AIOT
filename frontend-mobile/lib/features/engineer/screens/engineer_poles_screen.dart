import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/pole_provider.dart';
import '../../common/widgets/status_badge.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class EngineerPolesScreen extends StatefulWidget {
  const EngineerPolesScreen({super.key});

  @override
  State<EngineerPolesScreen> createState() => _EngineerPolesScreenState();
}

class _EngineerPolesScreenState extends State<EngineerPolesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final poleProvider = Provider.of<PoleProvider>(context);
    final poles = poleProvider.poles.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.id.toLowerCase().contains(q) ||
          p.locationName.toLowerCase().contains(q) ||
          p.zone.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribution Pole Fleet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => poleProvider.loadPoles(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Pole ID, Location, or Zone...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: poles.isEmpty
                ? const Center(child: Text('No poles found matching query.', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: poles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = poles[index];
                      return Card(
                        color: AppTheme.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: p.riskTier.color.withValues(alpha: 0.5)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: p.id)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(p.id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(4)),
                                          child: Text(p.zone, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                        ),
                                      ],
                                    ),
                                    StatusBadge(tier: p.riskTier, isCompact: true),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${p.locationName} • ${p.address ?? "Sub-Division Distribution"}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const Divider(color: AppTheme.borderDark, height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMetric('Leakage', '${p.leakageCurrent.toStringAsFixed(1)} mA', p.leakageCurrent > 30 ? AppTheme.emergencyColor : AppTheme.safeColor),
                                    _buildMetric('Touch Volt', '${p.voltage.toStringAsFixed(0)} V', p.voltage > 50 ? AppTheme.dangerColor : AppTheme.safeColor),
                                    _buildMetric('Health', '${p.healthScore}%', AppTheme.infoColor),
                                    _buildMetric('CRI Risk', '${p.riskScore}/100', p.riskTier.color),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
