import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// Process 1.0: Registration & Sign In (`GUI/Sign in.png`, `GUI/Sign up.png`).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final _emailCtrl = TextEditingController(text: '083370@putra.unisza.edu.my');
  final _passwordCtrl = TextEditingController(text: 'Password@123');
  final _fullNameCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _matricCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isSignUp) {
        if (_emailCtrl.text.trim().isEmpty ||
            _fullNameCtrl.text.trim().isEmpty ||
            _matricCtrl.text.trim().isEmpty) {
          throw Exception('Please fill in email, full name, and matric no.');
        }
        await widget.controller.registerAccount(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          participantCode: _matricCtrl.text.trim(),
        );
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Account created in ACCOUNT & PARTICIPANT tables!'),
            backgroundColor: UniScoutColors.success,
          ),
        );
      } else {
        await widget.controller.signInWithEmail(_emailCtrl.text);
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
              const SizedBox(height: 20),
              const Text(
                'UniScout',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: UniScoutColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'UniSZA Campus Event & Opportunity Management',
                textAlign: TextAlign.center,
                style: TextStyle(color: UniScoutColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 28),
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
                      _isSignUp ? 'Create Account (Process 1.0)' : 'Sign in',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isSignUp) ...[
                      TextField(
                        controller: _fullNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _matricCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Matric No. (e.g. 084500)',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'University Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: UniScoutColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSignUp ? 'CREATE ACCOUNT (INSERT)' : 'SIGN IN',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Sign up",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Demo Login (Switch Actor Role for CRUD Presentation)',
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

