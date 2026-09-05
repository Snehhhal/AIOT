import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/incident_model.dart';
import '../../../services/api_client.dart';
import '../../../services/pole_provider.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class AuthorityEscalationsScreen extends StatefulWidget {
  const AuthorityEscalationsScreen({super.key});

  @override
  State<AuthorityEscalationsScreen> createState() => _AuthorityEscalationsScreenState();
}

class _AuthorityEscalationsScreenState extends State<AuthorityEscalationsScreen> {
  List<IncidentModel> _escalations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEscalations();
  }

  Future<void> _loadEscalations() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiClient.getEscalations();
      if (mounted) setState(() { _escalations = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmGridCutoff(String poleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppTheme.emergencyColor),
            SizedBox(width: 8),
            Text('Remote Grid Isolation'),
          ],
        ),
        content: Text('Are you sure you want to execute an EMERGENCY POWER GRID CUTOFF for pole $poleId? This will immediately trip the substation breaker for this line.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiClient.orderGridCutoff(poleId, reason: 'Authority emergency trip order due to public electrocution hazard');
              if (mounted) {
                final poleProvider = Provider.of<PoleProvider>(context, listen: false);
                poleProvider.loadPoles();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Power cutoff order executed for $poleId. Substation tripped.' : 'Grid cutoff signal sent.'),
                    backgroundColor: AppTheme.emergencyColor,
                  ),
                );
                _loadEscalations();
              }
            },
            child: const Text('EXECUTE CUTOFF', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Escalation Queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEscalations)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _escalations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_user_rounded, size: 54, color: AppTheme.safeColor),
                        SizedBox(height: 12),
                        Text('No Overdue Escalations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        SizedBox(height: 6),
                        Text('All critical distribution incidents have been acknowledged within SLA.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _escalations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final e = _escalations[index];
                    return Card(
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
                                Text('ESCALATION #${e.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emergencyColor)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.emergencyColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('OVERDUE ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emergencyColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Pole: ${e.poleId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text(e.description, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.show_chart, size: 16),
                                    label: const Text('Diagnostics', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: e.poleId)));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyColor),
                                    icon: const Icon(Icons.power_settings_new, size: 16),
                                    label: const Text('Cutoff Grid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _confirmGridCutoff(e.poleId),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
