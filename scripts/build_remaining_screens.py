# Generator script
import os

BASE = r'frontend-mobile\lib'

def write_file(rel_path, content):
    full_path = os.path.join(BASE, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\n')
    print(f'Generated: {rel_path}')

# 1. engineer_poles_screen.dart
write_file('features/engineer/screens/engineer_poles_screen.dart', """
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pole_model.dart';
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
                          side: BorderSide(color: p.riskTier.color.withOpacity(0.5)),
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
""")

# 2. engineer_incidents_screen.dart
write_file('features/engineer/screens/engineer_incidents_screen.dart', """
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
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
                          side: BorderSide(color: color.withOpacity(0.5)),
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
                                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
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
""")

# 3. authority_zones_screen.dart
write_file('features/authority/screens/authority_zones_screen.dart', """
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
""")

# 4. authority_escalations_screen.dart
write_file('features/authority/screens/authority_escalations_screen.dart', """
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
""")

# 5. admin_users_screen.dart
write_file('features/admin/screens/admin_users_screen.dart', """
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiClient.getAdminUsers();
      if (mounted) setState(() { _users = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Staff Account Registry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found in database.', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      final roleStr = u['role']?.toString() ?? 'CITIZEN';
                      final isActive = u['is_active'] == true;

                      return Card(
                        color: AppTheme.surfaceDark,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.cardDark,
                            child: Icon(Icons.person, color: isActive ? AppTheme.infoColor : AppTheme.textSecondary),
                          ),
                          title: Text(u['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${u['email']} • $roleStr • ${u['zone'] ?? \"Zone 1\"}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isActive ? AppTheme.safeColor : AppTheme.dangerColor).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(isActive ? 'ACTIVE' : 'DISABLED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppTheme.safeColor : AppTheme.dangerColor)),
                              ),
                              IconButton(
                                icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline, size: 18, color: isActive ? AppTheme.warningColor : AppTheme.safeColor),
                                tooltip: isActive ? 'Deactivate User' : 'Activate User',
                                onPressed: () async {
                                  final success = await ApiClient.toggleUserActive(u['id']);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated active status for ${u['email']}')));
                                    _loadUsers();
                                  }
                                },
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
""")

# 6. admin_audit_screen.dart
write_file('features/admin/screens/admin_audit_screen.dart', """
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiClient.getAuditLogs(limit: 50);
      if (mounted) setState(() { _logs = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Security & Audit Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('No audit logs recorded yet.', style: TextStyle(color: AppTheme.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Card(
                        color: AppTheme.surfaceDark,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(log['action'] ?? 'ACTION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.infoColor)),
                                  Text(log['timestamp'] != null ? log['timestamp'].toString().substring(11, 19) : '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Target: ${log['target_entity'] ?? \"System\"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(height: 2),
                              Text(log['details'] ?? 'No extra details', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
""")

# 7. role_shell_screen.dart
write_file('features/navigation/screens/role_shell_screen.dart', """
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

import '../../citizen/screens/citizen_home_screen.dart';
import '../../citizen/screens/citizen_report_screen.dart';
import '../../citizen/screens/citizen_reports_screen.dart';
import '../../citizen/screens/citizen_chat_screen.dart';

import '../../technician/screens/technician_home_screen.dart';
import '../../technician/screens/technician_incidents_screen.dart';
import '../../technician/screens/technician_work_screen.dart';

import '../../engineer/screens/engineer_home_screen.dart';
import '../../engineer/screens/engineer_poles_screen.dart';
import '../../engineer/screens/engineer_incidents_screen.dart';

import '../../authority/screens/authority_home_screen.dart';
import '../../authority/screens/authority_escalations_screen.dart';
import '../../authority/screens/authority_zones_screen.dart';

import '../../admin/screens/admin_home_screen.dart';
import '../../admin/screens/admin_users_screen.dart';
import '../../admin/screens/admin_audit_screen.dart';

import '../../common/screens/profile_screen.dart';
import '../../common/widgets/connectivity_banner.dart';

class RoleShellScreen extends StatefulWidget {
  const RoleShellScreen({super.key});

  @override
  State<RoleShellScreen> createState() => _RoleShellScreenState();
}

class _RoleShellScreenState extends State<RoleShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = auth.currentRole;

    final pages = _getPagesForRole(role);
    final clampedIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.appName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(role.icon, size: 12, color: role.roleColor),
                const SizedBox(width: 4),
                Text(
                  role.displayName.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: role.roleColor, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: role.roleColor.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            icon: Icon(Icons.swap_horiz_rounded, size: 16, color: role.roleColor),
            label: Text('Switch Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: role.roleColor)),
            onPressed: () => _showRoleSwitchModal(context, auth),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout',
            onPressed: () => auth.logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: pages[clampedIndex]),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(role, clampedIndex),
    );
  }

  List<Widget> _getPagesForRole(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return const [
          CitizenHomeScreen(),
          CitizenReportsScreen(),
          CitizenReportScreen(),
          CitizenChatScreen(),
          ProfileScreen(),
        ];
      case UserRole.technician:
        return const [
          TechnicianHomeScreen(),
          TechnicianIncidentsScreen(),
          TechnicianWorkScreen(),
          CitizenChatScreen(),
          ProfileScreen(),
        ];
      case UserRole.engineer:
        return const [
          EngineerHomeScreen(),
          EngineerPolesScreen(),
          EngineerIncidentsScreen(),
          CitizenChatScreen(),
          ProfileScreen(),
        ];
      case UserRole.authority:
        return const [
          AuthorityHomeScreen(),
          AuthorityEscalationsScreen(),
          AuthorityZonesScreen(),
          AdminAuditScreen(),
          ProfileScreen(),
        ];
      case UserRole.admin:
        return const [
          AdminHomeScreen(),
          EngineerPolesScreen(),
          AdminUsersScreen(),
          AdminAuditScreen(),
          ProfileScreen(),
        ];
    }
  }

  Widget _buildBottomNav(UserRole role, int currentIndex) {
    List<BottomNavigationBarItem> items = [];

    switch (role) {
      case UserRole.citizen:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Safety Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'My Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo_rounded), label: 'Report Hazard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.technician:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Incidents'),
          BottomNavigationBarItem(icon: Icon(Icons.handyman_rounded), label: 'Work Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'SOP Guide'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.engineer:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Fleet Health'),
          BottomNavigationBarItem(icon: Icon(Icons.electrical_services_rounded), label: 'Poles'),
          BottomNavigationBarItem(icon: Icon(Icons.alt_route_rounded), label: 'Dispatch'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'AI Anomaly'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.authority:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Zone Safety'),
          BottomNavigationBarItem(icon: Icon(Icons.priority_high_rounded), label: 'Escalations'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Risk Zones'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Audit Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
      case UserRole.admin:
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Platform'),
          BottomNavigationBarItem(icon: Icon(Icons.electrical_services_rounded), label: 'Poles'),
          BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: 'Audit Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
        break;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: AppTheme.surfaceDark,
      selectedItemColor: role.roleColor,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
      items: items,
    );
  }

  void _showRoleSwitchModal(BuildContext context, AuthService auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Demo Role Switcher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Select any role to test dynamic role-based UI and access control:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ...UserRole.values.map((r) {
                final isCurrent = r == auth.currentRole;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.roleColor.withOpacity(0.15),
                    child: Icon(r.icon, color: r.roleColor, size: 20),
                  ),
                  title: Text(
                    r.displayName,
                    style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? r.roleColor : AppTheme.textPrimary),
                  ),
                  subtitle: Text('Role ID: ${r.id}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  trailing: isCurrent ? Icon(Icons.check_circle, color: r.roleColor, size: 20) : null,
                  onTap: () {
                    auth.quickDemoLogin(r);
                    setState(() => _currentIndex = 0);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
""")

print("All screens generated successfully!")

# Validate relative imports
import glob, re
dart_files = glob.glob(r'frontend-mobile\lib\**\*.dart', recursive=True)
errors = 0
for f in dart_files:
    dir_path = os.path.dirname(f)
    with open(f, 'r', encoding='utf-8') as file:
        for i, line in enumerate(file, 1):
            m = re.match(r"^\s*import\s+['\"](\.\.?/[^'\"]+)['\"]", line)
            if m:
                target = os.path.normpath(os.path.join(dir_path, m.group(1)))
                if not os.path.exists(target):
                    print(f"Broken import in {f}:{i} -> {target}")
                    errors += 1

if errors == 0:
    print(f"Validation PASSED: All relative imports across {len(dart_files)} Dart files are valid!")
else:
    print(f"Validation FAILED: {errors} broken imports found.")
