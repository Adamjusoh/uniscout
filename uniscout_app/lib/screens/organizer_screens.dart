import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// Member 2 CRUD (Process 3.1, 3.2, 3.3): Organizer Event Management.
class OrganizerEventsTab extends StatelessWidget {
  const OrganizerEventsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final oid = controller.currentOrganizerId;
    final orgEvents = controller.events
        .where((e) => e['organizer_id'] == oid || controller.currentRole == 'admin')
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventFormDialog(context),
        backgroundColor: UniScoutColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Event (3.1)'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
        itemCount: orgEvents.length,
        itemBuilder: (ctx, i) {
          final e = orgEvents[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: UniScoutColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        e['event_id'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: UniScoutColors.primary,
                        ),
                      ),
                      const Spacer(),
                      StatusBadge(code: e['event_status'] as String),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e['title'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${e['category_name']} · ${e['event_mode']} · ${e['location']}',
                    style: const TextStyle(fontSize: 12, color: UniScoutColors.muted),
                  ),
                  Text(
                    'Start: ${e['start_datetime']} · Quota: ${e['capacity']}',
                    style: const TextStyle(fontSize: 12, color: UniScoutColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit (3.2)'),
                        onPressed: () => _showEventFormDialog(context, existing: e),
                      ),
                      if (e['event_status'] != 'X')
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel (3.3)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UniScoutColors.warning,
                          ),
                          onPressed: () => runCrudAction(
                            context,
                            () => controller.cancelEvent(
                              eventId: e['event_id'] as String,
                              reason: 'Cancelled by organizer',
                            ),
                          ),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: UniScoutColors.danger,
                        ),
                        onPressed: () => runCrudAction(
                          context,
                          () => controller.deleteEvent(e['event_id'] as String),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEventFormDialog(
    BuildContext context, {
    Map<String, dynamic>? existing,
  }) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(
      text: (existing?['title'] as String?) ?? '',
    );
    final descCtrl = TextEditingController(
      text: (existing?['description'] as String?) ??
          'Hands-on campus workshop organized via UniScout.',
    );
    final locCtrl = TextEditingController(
      text: (existing?['location'] as String?) ?? 'Makmal Al-Biruni 3',
    );
    final capCtrl = TextEditingController(
      text: (existing?['capacity']?.toString()) ?? '60',
    );
    String catId = (existing?['category_id'] as String?) ??
        (controller.categories.first['category_id'] as String);
    String mode = (existing?['event_mode'] as String?) ?? 'Physical';
    String status = (existing?['event_status'] as String?) ?? 'P';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(
            isEdit ? 'Edit Event (${existing['event_id']})' : 'Create Event (3.1)',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                ),
                const SizedBox(height: 8),
                LabeledDropdown<String>(
                  label: 'Category',
                  value: catId,
                  items: controller.categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c['category_id'] as String,
                          child: Text(c['category_name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => catId = v ?? catId),
                ),
                const SizedBox(height: 8),
                LabeledDropdown<String>(
                  label: 'Mode',
                  value: mode,
                  items: ['Physical', 'Online', 'Hybrid']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setModalState(() => mode = v ?? mode),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Venue / Location'),
                ),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                ),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                LabeledDropdown<String>(
                  label: 'Status',
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'D', child: Text('Draft (D)')),
                    DropdownMenuItem(value: 'P', child: Text('Pending Approval (P)')),
                    DropdownMenuItem(value: 'A', child: Text('Approved (A)')),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final cap = int.tryParse(capCtrl.text.trim()) ?? 50;
                const start = '2026-12-12 09:00:00';
                const end = '2026-12-12 17:00:00';
                const deadline = '2026-12-10 23:59:59';
                final ok = await runCrudAction(
                  context,
                  () => isEdit
                      ? controller.updateEvent(
                          eventId: existing['event_id'] as String,
                          categoryId: catId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          eventMode: mode,
                          location: locCtrl.text.trim(),
                          startDatetime:
                              (existing['start_datetime'] as String?) ?? start,
                          endDatetime:
                              (existing['end_datetime'] as String?) ?? end,
                          regDeadline:
                              (existing['reg_deadline'] as String?) ?? deadline,
                          capacity: cap,
                          eligibilityCriteria:
                              (existing['eligibility_criteria'] as String?) ??
                                  'All UniSZA students',
                          eventStatus: status,
                        )
                      : controller.createEvent(
                          organizerId: controller.currentOrganizerId,
                          categoryId: catId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          eventMode: mode,
                          location: locCtrl.text.trim(),
                          startDatetime: start,
                          endDatetime: end,
                          regDeadline: deadline,
                          capacity: cap,
                          eligibilityCriteria: 'All UniSZA students',
                          eventStatus: status,
                        ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save (UPDATE)' : 'Submit (INSERT)'),
            ),
          ],
        ),
      ),
    );
  }
}

