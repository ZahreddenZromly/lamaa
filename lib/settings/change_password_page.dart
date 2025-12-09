import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_theme.dart';
import 'app_strings.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  String? _errorText;
  String? _successText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final loc = S.of(context);

    setState(() {
      _loading = true;
      _errorText = null;
      _successText = null;
    });

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _loading = false;
        _errorText = loc.fillAllFieldsError;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _loading = false;
        _errorText = loc.newPasswordTooShortError;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _loading = false;
        _errorText = loc.passwordsDontMatchError;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Not logged in.');
      }

      // 1. Re-authenticate with current password
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Update password
      await user.updatePassword(newPassword);

      setState(() {
        _loading = false;
        _successText = loc.passwordUpdatedSuccess;
      });

      // Optionally clear fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = loc.currentPasswordIncorrect;
          break;
        case 'weak-password':
          msg = loc.weakPasswordError;
          break;
        case 'requires-recent-login':
          msg = loc.requiresRecentLoginError;
          break;
        default:
          msg = e.message ?? loc.failedToChangePassword;
      }
      setState(() {
        _loading = false;
        _errorText = msg;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorText = loc.genericError(e.toString());
      });
    }
  }

  Future<void> _sendResetEmail() async {
    final loc = S.of(context);

    setState(() {
      _errorText = null;
      _successText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Not logged in.');
      }

      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: user.email!);

      setState(() {
        _successText = loc.resetEmailSent(user.email!);
      });
    } catch (e) {
      setState(() {
        _errorText = loc.sendResetEmailError(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.changePasswordTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.changePasswordHeading,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.changePasswordDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.currentPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.newPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_reset),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.confirmNewPasswordLabel,
                        prefixIcon:
                        const Icon(Icons.check_circle_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorText != null)
                      Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    if (_successText != null)
                      Text(
                        _successText!,
                        style: const TextStyle(color: AppColors.green),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _changePassword,
                        child: _loading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                            : Text(loc.saveNewPasswordButton),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _sendResetEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: Text(loc.sendResetEmailInstead),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
