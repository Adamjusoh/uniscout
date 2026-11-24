import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Design tokens aligned with `GUI/*.png` Figma mobile mockups.
class UniScoutColors {
  static const Color primary = Color(0xFF4E60FF);
  static const Color primarySoft = Color(0xFFEEF1FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
}

/// Runs an async CRUD action uniformly with snackbar feedback.
Future<bool> runCrudAction(
  BuildContext context,
  Future<Map<String, dynamic>> Function() action, {
  String? fallbackMessage,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final res = await action();
    messenger.showSnackBar(
      SnackBar(
        content: Text((res['message'] as String?) ?? fallbackMessage ?? 'Done'),
        backgroundColor: UniScoutColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: UniScoutColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }
}

/// Maps UniScout lifecycle status codes (`A`, `P`, `D`, `R`, `X`, `S`, etc.) to a pill.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.code, this.prefix = ''});

  final String code;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (code) {
      'A' => ('Approved / Active', UniScoutColors.success),
      'P' => ('Pending', UniScoutColors.warning),
      'D' => ('Draft', UniScoutColors.muted),
      'R' => ('Registered / Rejected', UniScoutColors.primary),
      'C' => ('Cancelled', UniScoutColors.danger),
      'X' => ('Cancelled', UniScoutColors.danger),
      'S' => ('Suspended', UniScoutColors.danger),
      'I' => ('Inactive', UniScoutColors.muted),
      'W' => ('Waitlist', UniScoutColors.warning),
      _ => (code, UniScoutColors.muted),
    };
    final text = prefix.isEmpty ? label : '$prefix: $label';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Reusable dropdown field without deprecated FormField `value:` parameters.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Live SQL & SDD Process inspector strip shown during CRUD presentations.
class SqlTraceBanner extends StatelessWidget {
  const SqlTraceBanner({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                controller.isConnectedToMySql
                    ? Icons.storage_rounded
                    : Icons.developer_mode_rounded,
                size: 14,
                color: controller.isConnectedToMySql
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFFBBF24),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  controller.isConnectedToMySql
                      ? 'MySQL Workbench LIVE (${controller.dbName}) · ${controller.lastSddRef}'
                      : 'Demo Mode (In-Memory) · ${controller.lastSddRef}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: const Size(0, 24),
                ),
                onPressed: () => showDbSettingsDialog(context, controller),
                child: const Text(
                  'MySQL Setup',
                  style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            controller.lastSqlTrace,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: 'monospace',
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for connecting Flutter directly to the user's MySQL Workbench server.
Future<void> showDbSettingsDialog(
  BuildContext context,
  UniScoutController controller,
) async {
  final urlCtrl = TextEditingController(text: controller.apiUrl);
  final hostCtrl = TextEditingController(text: controller.dbHost);
  final portCtrl = TextEditingController(text: controller.dbPort);
  final userCtrl = TextEditingController(text: controller.dbUser);
  final passCtrl = TextEditingController(text: controller.dbPassword);
  final nameCtrl = TextEditingController(text: controller.dbName);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('MySQL Workbench Connection'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Run ./start_backend.sh in terminal.\n'
              '2. Enter your MySQL Workbench password below and tap Test & Connect.',
              style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Local PHP API URL',
                hintText: 'http://10.0.2.2:8080/api.php (Emulator)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: hostCtrl,
                    decoration: const InputDecoration(labelText: 'MySQL Host'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: portCtrl,
                    decoration: const InputDecoration(labelText: 'Port'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(labelText: 'DB User'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'DB Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Schema Name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            controller.updateDbConfig(
              url: urlCtrl.text,
              host: hostCtrl.text,
              port: portCtrl.text,
              user: userCtrl.text,
              password: passCtrl.text,
              database: nameCtrl.text,
            );
            final messenger = ScaffoldMessenger.of(ctx);
            try {
              final msg = await controller.initializeMySqlDatabase();
              if (ctx.mounted) Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: UniScoutColors.success,
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: UniScoutColors.danger,
                ),
              );
            }
          },
          child: const Text('Init / Reset SQL'),
        ),
        FilledButton(
          onPressed: () async {
            controller.updateDbConfig(
              url: urlCtrl.text,
              host: hostCtrl.text,
              port: portCtrl.text,
              user: userCtrl.text,
              password: passCtrl.text,
              database: nameCtrl.text,
            );
            final messenger = ScaffoldMessenger.of(ctx);
            final ok = await controller.refreshFromServer();
            if (ok && ctx.mounted) {
              Navigator.of(ctx).pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Connected live to MySQL Workbench (uniscout_db)!'),
                  backgroundColor: UniScoutColors.success,
                ),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(controller.lastError ?? 'Failed to connect'),
                  backgroundColor: UniScoutColors.danger,
                ),
              );
            }
          },
          child: const Text('Test & Connect'),
        ),
      ],
    ),
  );
}

