import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/incident_model.dart';
import '../../../services/api_client.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class EngineerIncidentsScreen extends StatefulWidget {
  const EngineerIncidentsScreen({super.key});

  @override
  State<EngineerIncidentsScreen> createState() => _EngineerIncidentsScreenState();
}

class _EngineerIncidentsScreenState extends State<EngineerIncidentsScreen> {
  List<IncidentModel> _incidents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiClient.getIncidents();
      if (mounted) setState(() { _incidents = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssignDialog(IncidentModel inc) {
    final techController = TextEditingController(text: 'lineman14@poleguard.internal');
    final notesController = TextEditingController(text: 'Urgent: Inspect pole earthing and insulation.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Assign Incident ${inc.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: techController, decoration: const InputDecoration(labelText: 'Technician Email / ID')),
            const SizedBox(height: 10),
            TextField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Dispatch Instructions')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiClient.assignIncident(inc.id, techController.text.trim(), notes: notesController.text.trim());
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incident ${inc.id} assigned to ${techController.text}.'), backgroundColor: AppTheme.safeColor));
                _loadIncidents();
              }
            },
            child: const Text('Dispatch Work Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Dispatch & Incidents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIncidents)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Center(child: Text('No active incidents requiring dispatch.', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _loadIncidents,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _incidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final inc = _incidents[index];
                      final isEmergency = inc.severity == 'EMERGENCY' || inc.severity == 'CRITICAL';
                      final color = isEmergency ? AppTheme.emergencyColor : AppTheme.warningColor;

                      return Card(
                        color: AppTheme.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(inc.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(inc.severity, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Pole: ${inc.poleId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.infoColor)),
                              const SizedBox(height: 4),
                              Text(inc.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Status: ${inc.status}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(minimumSize: const Size(80, 36)),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: inc.poleId)));
                                        },
                                        child: const Text('View Pole', style: TextStyle(fontSize: 11)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoColor, minimumSize: const Size(100, 36)),
                                        icon: const Icon(Icons.send_rounded, size: 14),
                                        label: const Text('Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showAssignDialog(inc),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
