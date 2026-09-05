import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hazard_report_model.dart';
import '../../../services/api_client.dart';
import 'citizen_report_screen.dart';

class CitizenReportsScreen extends StatefulWidget {
  const CitizenReportsScreen({super.key});

  @override
  State<CitizenReportsScreen> createState() => _CitizenReportsScreenState();
}

class _CitizenReportsScreenState extends State<CitizenReportsScreen> {
  List<HazardReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() async {
    setState(() => _isLoading = true);
    final list = await ApiClient.getHazardReports();
    setState(() {
      _reports = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('My Hazard Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.dangerColor,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CitizenReportScreen()),
          );
          _loadReports();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.infoColor))
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => _loadReports(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: _reports.length,
                    itemBuilder: (ctx, idx) => _ReportCard(report: _reports[idx]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_turned_in_outlined, size: 36, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Hazard Reports Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'You have not submitted any pole hazard reports yet. If you spot sparking, waterlogging, or leaning wires, report them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: const Text('Report Hazard Now'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenReportScreen()),
                );
                _loadReports();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final HazardReportModel report;
  const _ReportCard({required this.report});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REPORTED':
        return AppTheme.warningColor;
      case 'UNDER_REVIEW':
        return Colors.amber;
      case 'VERIFIED':
      case 'ASSIGNED':
        return AppTheme.infoColor;
      case 'IN_PROGRESS':
        return Colors.orangeAccent;
      case 'RESOLVED':
      case 'CLOSED':
        return AppTheme.successColor;
      case 'REJECTED':
        return AppTheme.dangerColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  report.statusDisplay.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.hazardType,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            report.description,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Lifecycle steps indicator
          _buildLifecycleBar(report.statusStep, statusColor),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.address ?? '${report.latitude.toStringAsFixed(3)}, ${report.longitude.toStringAsFixed(3)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              Text(
                '${report.createdAt.day}/${report.createdAt.month} ${report.createdAt.hour}:${report.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),

          if (report.inspectionNotes != null && report.inspectionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lineman Log: ${report.inspectionNotes}',
                style: const TextStyle(fontSize: 11, color: Colors.cyanAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifecycleBar(int activeStep, Color activeColor) {
    final stages = ['Reported', 'Review', 'Assigned', 'In Progress', 'Resolved'];

    return Row(
      children: List.generate(stages.length, (index) {
        final isDone = index <= activeStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: isDone ? activeColor : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
