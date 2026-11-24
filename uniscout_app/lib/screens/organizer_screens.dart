import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// SDD Section 3.3 (Pages 29-39): Organizer Manage Events (Create, Edit, Cancel).
class OrganizerEventsTab extends StatelessWidget {
  const OrganizerEventsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final oid = controller.currentOrganizerId;
    final orgEvents = controller.events
        .where(
          (e) =>
              e['organizer_id'] == oid || controller.currentRole == 'admin',
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Managed Campus Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CreateEditEventScreen(controller: controller),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: UniScoutColors.primary,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Event'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (orgEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No events created yet.')),
            ),
          ...orgEvents.map((e) {
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${e['category_name']} · ${e['event_mode']} · ${e['location']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: UniScoutColors.muted,
                      ),
                    ),
                    Text(
                      'Start: ${e['start_datetime']} · Quota: ${e['capacity']} Seats',
                      style: const TextStyle(
                        fontSize: 12,
                        color: UniScoutColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit campus event'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CreateEditEventScreen(
                                  controller: controller,
                                  existing: e,
                                ),
                              ),
                            );
                          },
                        ),
                        if (e['event_status'] != 'X')
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Cancel event'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: UniScoutColors.danger,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CancelEventScreen(
                                    controller: controller,
                                    event: e,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// SDD Pages 32 & 36: "Create Campus Event" & "Edit campus event" full page.
class CreateEditEventScreen extends StatefulWidget {
  const CreateEditEventScreen({
    super.key,
    required this.controller,
    this.existing,
  });

  final UniScoutController controller;
  final Map<String, dynamic>? existing;

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _deadlineCtrl;
  late String _categoryId;
  late String _mode;
  bool _fikOnly = true;
  bool _bannerUploaded = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: (e?['title'] as String?) ?? '');
    _descCtrl = TextEditingController(
      text: (e?['description'] as String?) ??
          'Build Flutter widgets, explore state management, and create a full-stack mobile app.',
    );
    _venueCtrl = TextEditingController(
      text: (e?['location'] as String?) ?? 'Makmal Al-Biruni 3, FIK',
    );
    _startCtrl = TextEditingController(
      text: (e?['start_datetime'] as String?) ?? '2026-12-18 09:00:00',
    );
    _endCtrl = TextEditingController(
      text: (e?['end_datetime'] as String?) ?? '2026-12-18 17:00:00',
    );
    _capacityCtrl = TextEditingController(
      text: (e?['capacity']?.toString()) ?? '50',
    );
    _deadlineCtrl = TextEditingController(
      text: (e?['reg_deadline'] as String?) ?? '2026-12-15 23:59:59',
    );
    _categoryId = (e?['category_id'] as String?) ??
        (widget.controller.categories.first['category_id'] as String);
    _mode = (e?['event_mode'] as String?) ?? 'Physical';
    _fikOnly = ((e?['eligibility_criteria'] as String?) ?? '')
        .toLowerCase()
        .contains('fik');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _capacityCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_titleCtrl.text.trim().isEmpty ||
        _startCtrl.text.trim().isEmpty ||
        _deadlineCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: UniScoutColors.danger,
        ),
      );
      return;
    }
    if ((_mode == 'Physical' || _mode == 'Hybrid') &&
        _venueCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter venue/location'),
          backgroundColor: UniScoutColors.danger,
        ),
      );
      return;
    }
    final cap = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
    if (cap <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Invalid capacity quota'),
          backgroundColor: UniScoutColors.danger,
        ),
      );
      return;
    }

    final eligibility = _fikOnly
        ? 'Open to FIK Students Only'
        : 'Open to all UniSZA students';

    final ok = await runCrudAction(
      context,
      () => _isEdit
          ? widget.controller.updateEvent(
              eventId: widget.existing!['event_id'] as String,
              categoryId: _categoryId,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              eventMode: _mode,
              location: _venueCtrl.text.trim(),
              startDatetime: _startCtrl.text.trim(),
              endDatetime: _endCtrl.text.trim(),
              regDeadline: _deadlineCtrl.text.trim(),
              capacity: cap,
              eligibilityCriteria: eligibility,
              eventStatus: 'P',
            )
          : widget.controller.createEvent(
              organizerId: widget.controller.currentOrganizerId,
              categoryId: _categoryId,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              eventMode: _mode,
              location: _venueCtrl.text.trim(),
              startDatetime: _startCtrl.text.trim(),
              endDatetime: _endCtrl.text.trim(),
              regDeadline: _deadlineCtrl.text.trim(),
              capacity: cap,
              eligibilityCriteria: eligibility,
              eventStatus: 'P',
            ),
      fallbackMessage: _isEdit
          ? 'Changes submitted for review'
          : 'Event submitted for faculty approval',
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit campus event' : 'Create Campus Event',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              _isEdit
                  ? 'Published event • Changes require review'
                  : 'Step 1 of 2',
              style: TextStyle(
                fontSize: 12,
                color: _isEdit ? UniScoutColors.primary : UniScoutColors.muted,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_isEdit) ...[
            LinearProgressIndicator(
              value: 0.5,
              backgroundColor: UniScoutColors.border,
              color: UniScoutColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _bannerUploaded = !_bannerUploaded),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: UniScoutColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: UniScoutColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _bannerUploaded
                          ? Icons.check_circle
                          : Icons.image_outlined,
                      size: 32,
                      color: UniScoutColors.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _bannerUploaded
                          ? 'Event banner selected (16:9)'
                          : 'Tap to upload event banner (16:9)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: UniScoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Event Title',
              hintText: 'Enter event title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          if (_isEdit) ...[
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'About this event',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
          ],
          LabeledDropdown<String>(
            label: 'Category',
            value: _categoryId,
            items: widget.controller.categories
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c['category_id'] as String,
                    child: Text(c['category_name'] as String),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _categoryId = v ?? _categoryId),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mode',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['Physical', 'Online', 'Hybrid'].map((m) {
              final selected = _mode == m;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(child: Text(m)),
                    selected: selected,
                    onSelected: (_) => setState(() => _mode = m),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _venueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Venue / Location',
                    hintText: 'e.g. Makmal Al-Biruni 3',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Start Date & Time',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isEdit)
            TextField(
              controller: _endCtrl,
              decoration: const InputDecoration(
                labelText: 'Ends Date & Time',
                border: OutlineInputBorder(),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Capacity Quota',
                      hintText: 'e.g. 50 Seats',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _deadlineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Registration Deadline',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          if (!_isEdit)
            SwitchListTile(
              title: const Text(
                'Open to FIK Students Only',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text(
                'Limit eligibility to your faculty',
                style: TextStyle(fontSize: 12),
              ),
              value: _fikOnly,
              onChanged: (v) => setState(() => _fikOnly = v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: UniScoutColors.border),
              ),
            )
          else
            const Text(
              'Existing registrations will be kept. Approved changes will be shared with participants.',
              style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: UniScoutColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isEdit ? 'SUBMIT CHANGES FOR REVIEW' : 'SUBMIT FOR APPROVAL',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// SDD Section 3.3.3 (Page 39): Cancel event screen with reason & acknowledgement checkbox.
class CancelEventScreen extends StatefulWidget {
  const CancelEventScreen({
    super.key,
    required this.controller,
    required this.event,
  });

  final UniScoutController controller;
  final Map<String, dynamic> event;

  @override
  State<CancelEventScreen> createState() => _CancelEventScreenState();
}

class _CancelEventScreenState extends State<CancelEventScreen> {
  final _reasonCtrl = TextEditingController(
    text: 'Venue is unavailable due to a scheduling conflict.',
  );
  bool _acknowledged = true;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_reasonCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason for cancellation'),
          backgroundColor: UniScoutColors.danger,
        ),
      );
      return;
    }
    if (!_acknowledged) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm you understand this affects all registered participants',
          ),
          backgroundColor: UniScoutColors.danger,
        ),
      );
      return;
    }
    final ok = await runCrudAction(
      context,
      () => widget.controller.cancelEvent(
        eventId: widget.event['event_id'] as String,
        reason: _reasonCtrl.text.trim(),
      ),
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel event')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UniScoutColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will cancel the event for everyone.',
                  style: TextStyle(
                    color: UniScoutColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use this only if the event cannot go ahead.',
                  style: TextStyle(color: UniScoutColors.danger, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: UniScoutColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${e['start_datetime']}\n${e['location']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: UniScoutColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Reason for cancellation *',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Participants will be notified',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registrations and admission passes will be invalidated. The event will no longer accept registrations.',
            style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: _acknowledged,
            onChanged: (v) => setState(() => _acknowledged = v ?? false),
            title: const Text(
              'I understand this affects all registered participants.',
              style: TextStyle(fontSize: 13, color: UniScoutColors.danger),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _confirmCancel,
            style: FilledButton.styleFrom(
              backgroundColor: UniScoutColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'CONFIRM EVENT CANCELLATION',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep event'),
          ),
        ],
      ),
    );
  }
}
