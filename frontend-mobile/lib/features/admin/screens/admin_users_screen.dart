import 'package:flutter/material.dart';
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
                          subtitle: Text('${u['email']} • $roleStr • ${u['zone'] ?? "Zone 1"}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isActive ? AppTheme.safeColor : AppTheme.dangerColor).withValues(alpha: 0.15),
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
