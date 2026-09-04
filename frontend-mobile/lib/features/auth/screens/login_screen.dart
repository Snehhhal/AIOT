import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'citizen@safety.org');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.login(_emailController.text.trim(), _passwordController.text);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // App Logo / Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.infoColor, width: 2),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 44,
                    color: AppTheme.infoColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AI & IoT Leakage Detection in Electric Pole and Life Safety',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),

              // Standard Email & Password Form
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign In to Safety Portal'),
              ),
              const SizedBox(height: 30),

              // Quick Role Login for Demo / Evaluation (Section 51 Criteria 1-6)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.touch_app_rounded, size: 18, color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        const Text(
                          '1-Tap Demo Role Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select a persona to test the single Flutter app role-based interface:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildDemoRoleTile(
                      role: UserRole.citizen,
                      title: 'Citizen',
                      desc: 'Simple Green/Yellow/Red status, Report Hazard SOS',
                      onTap: () => auth.quickDemoLogin(UserRole.citizen),
                    ),
                    _buildDemoRoleTile(
                      role: UserRole.technician,
                      title: 'Field Technician',
                      desc: 'Acknowledge, Inspect, Work Orders, Offline sync',
                      onTap: () => auth.quickDemoLogin(UserRole.technician),
                    ),
                    _buildDemoRoleTile(
                      role: UserRole.engineer,
                      title: 'Supervisor / Engineer',
                      desc: 'Pole health scoring, AI anomaly feed, Dispatching',
                      onTap: () => auth.quickDemoLogin(UserRole.engineer),
                    ),
                    _buildDemoRoleTile(
                      role: UserRole.authority,
                      title: 'Municipal Authority',
                      desc: 'Area safety index, Overdue escalation review',
                      onTap: () => auth.quickDemoLogin(UserRole.authority),
                    ),
                    _buildDemoRoleTile(
                      role: UserRole.admin,
                      title: 'System Administrator',
                      desc: 'Platform health, Threshold config, Demo Control',
                      onTap: () => auth.quickDemoLogin(UserRole.admin),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoRoleTile({
    required UserRole role,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: role.roleColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: role.roleColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(role.icon, color: role.roleColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: role.roleColor,
                      ),
                    ),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: role.roleColor),
            ],
          ),
        ),
      ),
    );
  }
}
