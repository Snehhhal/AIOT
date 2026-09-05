import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/incident_model.dart';
import '../../../services/api_client.dart';
import '../../monitoring/screens/pole_detail_screen.dart';

class TechnicianIncidentsScreen extends StatefulWidget {
  const TechnicianIncidentsScreen({super.key});

  @override
  State<TechnicianIncidentsScreen> createState() => _TechnicianIncidentsScreenState();
}

class _TechnicianIncidentsScreenState extends State<TechnicianIncidentsScreen> {
  List<IncidentModel> _incidents = [];
  bool _isLoading = false;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiClient.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<IncidentModel> get _filteredIncidents {
    if (_selectedFilter == 'ALL') return _incidents;
    return _incidents.where((inc) => inc.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Incident Queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIncidents),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Tasks'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ASSIGNED', 'Assigned'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ACKNOWLEDGED', 'Acknowledged'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IN_PROGRESS', 'In Progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('RESOLVED', 'Resolved'),
                ],
              ),
            ),
          ),
          const Divider(color: AppTheme.borderDark, height: 1),

          // Incident List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIncidents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.assignment_turned_in_rounded, size: 48, color: AppTheme.safeColor),
                            SizedBox(height: 12),
                            Text('No incidents found in this category', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadIncidents,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredIncidents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final inc = _filteredIncidents[index];
                            return _buildIncidentCard(inc);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppTheme.infoColor,
      backgroundColor: AppTheme.cardDark,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = filterKey);
      },
    );
  }

  Widget _buildIncidentCard(IncidentModel inc) {
    final isEmergency = inc.severity == 'EMERGENCY' || inc.severity == 'CRITICAL';
    final severityColor = isEmergency ? AppTheme.emergencyColor : AppTheme.warningColor;

    return Card(
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: severityColor.withValues(alpha: 0.6), width: isEmergency ? 1.5 : 1.0),
      ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inc.severity,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: severityColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inc.id,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Text(
                    inc.status,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Pole Target: ',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              inc.description,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inc.status == 'DETECTED' || inc.status == 'ASSIGNED')
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.infoColor),
                      foregroundColor: AppTheme.infoColor,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Acknowledge', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final success = await ApiClient.acknowledgeIncident(inc.id);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incident  acknowledged.')),
                        );
                        _loadIncidents();
                      }
                    },
                  ),
                if (inc.status == 'ACKNOWLEDGED')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start Work', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final success = await ApiClient.updateIncidentStatus(inc.id, 'IN_PROGRESS', notes: 'Lineman arrived on site');
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incident  status updated to IN_PROGRESS.')),
                        );
                        _loadIncidents();
                      }
                    },
                  ),
                if (inc.status == 'IN_PROGRESS')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.safeColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark Resolved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final success = await ApiClient.updateIncidentStatus(inc.id, 'RESOLVED', notes: 'Repaired and safe.');
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incident  marked RESOLVED.')),
                        );
                        _loadIncidents();
                      }
                    },
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.insights_rounded, size: 16),
                  label: const Text('Pole Telemetry', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PoleDetailScreen(poleId: inc.poleId)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
