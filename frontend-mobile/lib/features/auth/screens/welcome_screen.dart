import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Top branding icon
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.infoColor.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: AppTheme.infoColor, size: 30),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to\n${AppConstants.appName}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'AI and IoT-based electric pole leakage detection and life safety platform for municipal utility infrastructure.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Feature Pillars
              Expanded(
                child: ListView(
                  children: const [
                    _FeatureTile(
                      icon: Icons.shield_rounded,
                      iconColor: AppTheme.successColor,
                      title: 'Public Life Safety',
                      description: 'Real-time leakage alerts, safety checks for nearby poles, and citizen photo reporting.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.sensors_rounded,
                      iconColor: AppTheme.warningColor,
                      title: 'Live IoT Telemetry',
                      description: 'Milliamperage leakage current, touch voltage, rain detection, and tilt angle monitoring.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.psychology_rounded,
                      iconColor: AppTheme.infoColor,
                      title: 'AI Decision Engine',
                      description: 'Random Forest tabular leakage prediction coupled with deterministic safety rule evaluation (CRI 0-100).',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.group_work_rounded,
                      iconColor: Colors.purpleAccent,
                      title: '5 Operational Roles',
                      description: 'Dedicated workflows for Citizens, Linemen, Engineers, Authorities, and Administrators.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // CTA Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started — Choose Role',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
