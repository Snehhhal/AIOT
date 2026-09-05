import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../navigation/screens/role_shell_screen.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final success = await auth.login(email, pass);
    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleShellScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Authentication failed.'),
          backgroundColor: AppTheme.dangerColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final role = auth.selectedRole;
    final loc = AppLocalizations(auth.currentLanguage);

    String portalTitle;
    String portalSubtitle;
    switch (role) {
      case UserRole.citizen:
        portalTitle = '${loc.tr('role_citizen_title')} ${loc.tr('login')}';
        portalSubtitle = loc.tr('role_citizen_tagline');
        break;
      case UserRole.technician:
        portalTitle = '${loc.tr('role_technician_title')} ${loc.tr('login')}';
        portalSubtitle = loc.tr('role_technician_tagline');
        break;
      case UserRole.engineer:
        portalTitle = '${loc.tr('role_engineer_title')} ${loc.tr('login')}';
        portalSubtitle = loc.tr('role_engineer_tagline');
        break;
      case UserRole.authority:
        portalTitle = '${loc.tr('role_authority_title')} ${loc.tr('login')}';
        portalSubtitle = loc.tr('role_authority_tagline');
        break;
      case UserRole.admin:
        portalTitle = '${loc.tr('role_admin_title')} ${loc.tr('login')}';
        portalSubtitle = loc.tr('role_admin_tagline');
        break;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              // Top Bar: Role badge, Change Role button, and Language Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: role.roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: role.roleColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(role.icon, size: 16, color: role.roleColor),
                        const SizedBox(width: 6),
                        Text(
                          role.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: role.roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: Text(loc.tr('change_role'), style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                          );
                        },
                      ),
                      // Language Selector
                      PopupMenuButton<AppLanguage>(
                        tooltip: loc.tr('select_language'),
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: AppTheme.surfaceDark,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Text(
                            auth.currentLanguage.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        onSelected: (AppLanguage selected) => auth.setLanguage(selected),
                        itemBuilder: (context) => AppLanguage.values.map((lang) {
                          final isSelected = lang == auth.currentLanguage;
                          return PopupMenuItem<AppLanguage>(
                            value: lang,
                            child: Row(
                              children: [
                                Text(lang.flag, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Text(
                                  lang.label,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.infoColor : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // App Logo / Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: role.roleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: role.roleColor.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 40,
                    color: role.roleColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                portalTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                portalSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),

              // Error display
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.dangerColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: loc.tr('email'),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: loc.tr('password'),
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 8),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(loc.tr('forgot_password'), style: const TextStyle(fontSize: 12, color: AppTheme.infoColor)),
                ),
              ),
              const SizedBox(height: 12),

              // Log In Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: role.roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: auth.isLoading ? null : _handleLogin,
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(loc.tr('login'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 24),

              // Register CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${loc.tr('dont_have_account')} ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: Text(
                      loc.tr('signup'),
                      style: TextStyle(color: role.roleColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
