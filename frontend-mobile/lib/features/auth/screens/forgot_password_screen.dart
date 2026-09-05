import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController(text: 'citizen@safety.org');
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRequestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isError = true;
        _message = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final res = await auth.forgotPassword(email);

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final token = res['data']?['reset_token'] ?? '';
      setState(() {
        _isCodeSent = true;
        _isError = false;
        _tokenController.text = token;
        _message = 'Reset code generated: $token. Set your new password below.';
      });
    } else {
      setState(() {
        _isError = true;
        _message = res['error'] ?? 'Could not generate reset code.';
      });
    }
  }

  void _handleResetPassword() async {
    final token = _tokenController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (token.isEmpty) {
      setState(() {
        _isError = true;
        _message = 'Please enter the reset verification token.';
      });
      return;
    }
    if (newPass.length < 6) {
      setState(() {
        _isError = true;
        _message = 'New password must be at least 6 characters.';
      });
      return;
    }
    if (newPass != confirmPass) {
      setState(() {
        _isError = true;
        _message = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final res = await auth.resetPassword(
      email: _emailController.text.trim(),
      token: token,
      newPassword: newPass,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please log in.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _isError = true;
        _message = res['error'] ?? 'Failed to reset password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppTheme.warningColor, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Forgot Your Password?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isCodeSent
                    ? 'Enter the verification token and your new password below.'
                    : 'Enter your registered account email to request a secure password reset token.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 24),

              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isError ? AppTheme.dangerColor : AppTheme.successColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_isError ? AppTheme.dangerColor : AppTheme.successColor).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isError ? AppTheme.dangerColor : AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email
              TextField(
                controller: _emailController,
                enabled: !_isCodeSent,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              if (!_isCodeSent) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleRequestCode,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Request Verification Token', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                // Token Field
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Reset Verification Token',
                    hintText: 'e.g. RST-XXXXXX',
                    prefixIcon: Icon(Icons.key_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // New Password
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_reset, color: AppTheme.textSecondary),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleResetPassword,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Set New Password & Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
