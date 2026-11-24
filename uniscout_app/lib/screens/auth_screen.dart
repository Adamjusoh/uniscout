import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// SDD Section 3.1 (Page 14): Sign in, Join UniScout (Sign up), and Reset Password.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _AuthView { signIn, signUp, resetPassword }

class _AuthScreenState extends State<AuthScreen> {
  _AuthView _view = _AuthView.signIn;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _emailCtrl = TextEditingController(text: '083370@putra.unisza.edu.my');
  final _passwordCtrl = TextEditingController(text: 'Password@123');
  final _confirmPasswordCtrl = TextEditingController(text: 'Password@123');
  final _fullNameCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _fullNameCtrl.dispose();
    _matricCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_view == _AuthView.signUp) {
        if (_emailCtrl.text.trim().isEmpty ||
            _fullNameCtrl.text.trim().isEmpty ||
            _matricCtrl.text.trim().isEmpty ||
            _passwordCtrl.text.isEmpty ||
            _confirmPasswordCtrl.text.isEmpty) {
          throw Exception('Please complete all required fields');
        }
        if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
          throw Exception('Passwords do not match');
        }
        await widget.controller.registerAccount(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          participantCode: _matricCtrl.text.trim(),
        );
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
            backgroundColor: UniScoutColors.success,
          ),
        );
      } else if (_view == _AuthView.signIn) {
        if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
          throw Exception('Invalid email or password');
        }
        await widget.controller.signInWithEmail(_emailCtrl.text);
      } else if (_view == _AuthView.resetPassword) {
        if (_emailCtrl.text.trim().isEmpty) {
          throw Exception('Please enter your UniSZA student email');
        }
        messenger.showSnackBar(
          const SnackBar(
            content: Text('If the account exists, reset instructions will be sent'),
            backgroundColor: UniScoutColors.primary,
          ),
        );
        setState(() => _view = _AuthView.signIn);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: UniScoutColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniScoutColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_view != _AuthView.signIn)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _view = _AuthView.signIn),
                    )
                  else
                    Chip(
                      avatar: Icon(
                        widget.controller.isConnectedToMySql
                            ? Icons.check_circle
                            : Icons.offline_bolt,
                        size: 16,
                        color: widget.controller.isConnectedToMySql
                            ? UniScoutColors.success
                            : UniScoutColors.warning,
                      ),
                      label: Text(
                        widget.controller.isConnectedToMySql
                            ? 'MySQL Live'
                            : 'Demo Mode',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () =>
                        showDbSettingsDialog(context, widget.controller),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('MySQL Setup'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_view == _AuthView.signIn) ...[
                const Text(
                  'UniScout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: UniScoutColors.ink,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: UniScoutColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      switch (_view) {
                        _AuthView.signIn => 'Sign in',
                        _AuthView.signUp => 'Join UniScout',
                        _AuthView.resetPassword => 'Reset Password',
                      },
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_view == _AuthView.resetPassword) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your UniSZA student email to request a password reset.',
                        style: TextStyle(
                          fontSize: 13,
                          color: UniScoutColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_view == _AuthView.signUp) ...[
                      TextField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name (e.g. Adam Hariz)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _matricCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Matric Number (e.g. 083370)',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'student@putra.unisza.edu.my',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    if (_view != _AuthView.resetPassword) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_view == _AuthView.signUp) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_view == _AuthView.signIn) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Switch(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v),
                          ),
                          const Text(
                            'Remember Me',
                            style: TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => _view = _AuthView.resetPassword),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: UniScoutColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        switch (_view) {
                          _AuthView.signIn => 'SIGN IN',
                          _AuthView.signUp => 'SIGN UP',
                          _AuthView.resetPassword => 'SEND',
                        },
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_view != _AuthView.resetPassword) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'OR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: UniScoutColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () =>
                            widget.controller.signInQuick('ACC-1004'),
                        icon: const Icon(Icons.school_outlined, size: 18),
                        label: const Text(
                          'Sign in with UniSZA Student Portal (AIMS SSO)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(
                          () => _view = _view == _AuthView.signUp
                              ? _AuthView.signIn
                              : _AuthView.signUp,
                        ),
                        child: Text(
                          _view == _AuthView.signUp
                              ? 'Already have an account? Sign in'
                              : "Don't have an account? Sign up",
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Demo Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: UniScoutColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _QuickRoleChip(
                    label: 'Participant (Adam)',
                    icon: Icons.school,
                    onTap: () => widget.controller.signInQuick('ACC-1004'),
                  ),
                  _QuickRoleChip(
                    label: 'Organizer (CSS)',
                    icon: Icons.event_note,
                    onTap: () => widget.controller.signInQuick('ACC-1002'),
                  ),
                  _QuickRoleChip(
                    label: 'Admin (HEPA)',
                    icon: Icons.admin_panel_settings,
                    onTap: () => widget.controller.signInQuick('ACC-1001'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRoleChip extends StatelessWidget {
  const _QuickRoleChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: UniScoutColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: UniScoutColors.border),
      onPressed: onTap,
    );
  }
}
