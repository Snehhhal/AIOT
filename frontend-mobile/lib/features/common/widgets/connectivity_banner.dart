import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isOffline = auth.isOffline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isOffline
          ? AppTheme.emergencyColor.withValues(alpha: 0.9)
          : AppTheme.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off_rounded : Icons.wifi_rounded,
                size: 16,
                color: isOffline ? Colors.white : AppTheme.safeColor,
              ),
              const SizedBox(width: 8),
              Text(
                isOffline
                    ? '🔴 OFFLINE MODE (Cached local operations active)'
                    : '🟢 ONLINE (Cloud Connected)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isOffline ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => auth.toggleOfflineMode(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOffline ? 'Simulate Online' : 'Simulate Offline',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
