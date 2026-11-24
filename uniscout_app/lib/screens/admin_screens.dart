import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// SDD Section 3.5 (Pages 51, 54, 57): Event Approvals (`GUI/Event Approvals.png`).
class AdminApprovalsTab extends StatefulWidget {
  const AdminApprovalsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<AdminApprovalsTab> createState() => _AdminApprovalsTabState();
}

class _AdminApprovalsTabState extends State<AdminApprovalsTab> {
  String _statusTab = 'P';

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.controller.events
        .where((e) => e['event_status'] == 'P')
        .length;
    final filtered = widget.controller.events
        .where((e) => e['event_status'] == _statusTab)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Event Approvals',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'UniSZA HEPA Governance',
          style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ('P', 'Pending ($pendingCount)'),
            ('A', 'Approved'),
            ('R', 'Rejected'),
          ].map((pair) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(pair.$2),
                selected: _statusTab == pair.$1,
                onSelected: (_) => setState(() => _statusTab = pair.$1),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: UniScoutColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: UniScoutColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.radar, color: UniScoutColors.warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Automated Venue Radar: No active clashes detected for today's submissions.",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No pending events found')),
          ),
        ...filtered.map((e) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: UniScoutColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: UniScoutColors.primarySoft,
                        child: Icon(
                          Icons.apartment,
                          size: 18,
                          color: UniScoutColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (e['org_name'] as String?) ?? 'Campus Club',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Submitted · ${e['event_id']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: UniScoutColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(code: e['event_status'] as String),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    e['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        Icons.place_outlined,
                        '${e['event_mode']} • ${e['location']}',
                      ),
                      _InfoPill(
                        Icons.calendar_today_outlined,
                        '${e['start_datetime']}',
                      ),
                      _InfoPill(
                        Icons.people_outline,
                        'Quota: ${e['capacity']} Students',
                      ),
                      _InfoPill(
                        Icons.workspace_premium_outlined,
                        'Merit Category: ${e['category_name']}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: UniScoutColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✓ Venue Available (No Clashing Schedule)',
                      style: TextStyle(
                        color: UniScoutColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _confirmReview(
                          context,
                          event: e,
                          approve: false,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: UniScoutColors.danger,
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _confirmReview(
                            context,
                            event: e,
                            approve: true,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: UniScoutColors.primary,
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Approve & Publish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _confirmReview(
    BuildContext context, {
    required Map<String, dynamic> event,
    required bool approve,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Confirm Approval' : 'Confirm Rejection'),
        content: Text(
          approve
              ? 'Approve and publish "${event['title']}"?'
              : 'Reject "${event['title']}" and notify the organizer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  approve ? UniScoutColors.primary : UniScoutColors.danger,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await runCrudAction(
      context,
      () => widget.controller.reviewEvent(
        eventId: event['event_id'] as String,
        status: approve ? 'A' : 'R',
        remarks: approve
            ? 'Event approved successfully'
            : 'Event rejected during HEPA review',
      ),
      fallbackMessage: approve
          ? 'Event approved successfully'
          : 'Event rejection successfully',
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: UniScoutColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UniScoutColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: UniScoutColors.muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: UniScoutColors.ink),
          ),
        ],
      ),
    );
  }
}

/// SDD Section 3.8.1 & 3.8.2 (Pages 73 & 77): Manage Users & Organizations.
class AdminManagementTab extends StatelessWidget {
  const AdminManagementTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Manage users'),
              Tab(text: 'Organizations'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _UsersView(controller: controller),
                _OrganizationsView(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView({required this.controller});

  final UniScoutController controller;

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  String _search = '';
  String _statusFilter = 'A'; // 'A' = Active, 'S' = Suspended, 'ALL' = All users
  Map<String, dynamic>? _selectedUser;
  String _selectedRole = 'participant';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = c.accounts.where((u) {
      if (_statusFilter != 'ALL' && u['account_status'] != _statusFilter) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final name = ((u['participant_name'] as String?) ??
                (u['organizer_name'] as String?) ??
                'Administrator')
            .toLowerCase();
        final email = (u['email'] as String).toLowerCase();
        final code = ((u['participant_code'] as String?) ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || code.contains(q);
      }
      return true;
    }).toList();

    final sel = _selectedUser ?? (users.isNotEmpty ? users.first : null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manage users',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'UniSZA Administration • Users & Students',
          style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _search = v.trim()),
          decoration: InputDecoration(
            hintText: 'Search by name, matric or email',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ('A', 'Active'),
            ('S', 'Suspended'),
            ('ALL', 'All users'),
          ].map((tab) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(tab.$2),
                selected: _statusFilter == tab.$1,
                onSelected: (_) => setState(() => _statusFilter = tab.$1),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        ...users.map((u) {
          final name = (u['participant_name'] as String?) ??
              (u['organizer_name'] as String?) ??
              'Administrator';
          final code = (u['participant_code'] as String?) ??
              (u['account_id'] as String);
          final isSelected = sel?['account_id'] == u['account_id'];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected
                    ? UniScoutColors.primary
                    : UniScoutColors.border,
              ),
            ),
            child: ListTile(
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('$code • ${u['role']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    u['account_status'] == 'A' ? 'Active' : 'Suspended',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: u['account_status'] == 'A'
                          ? UniScoutColors.success
                          : UniScoutColors.danger,
                    ),
                  ),
                  Text(
                    isSelected ? 'View details' : 'Manage',
                    style: const TextStyle(
                      fontSize: 12,
                      color: UniScoutColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              onTap: () => setState(() {
                _selectedUser = u;
                _selectedRole = (u['role'] as String?) ?? 'participant';
              }),
            ),
          );
        }),
        if (sel != null) ...[
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: UniScoutColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage ${(sel['participant_name'] as String?) ?? (sel['organizer_name'] as String?) ?? sel['account_id']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sel['email'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: UniScoutColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Account role',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['participant', 'organizer'].map((r) {
                      final active = _selectedRole == r;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Center(
                              child: Text(
                                r == 'participant'
                                    ? 'Participant'
                                    : 'Organizer',
                              ),
                            ),
                            selected: active,
                            onSelected: (_) =>
                                setState(() => _selectedRole = r),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Organizer access requires a verified organization.',
                    style: TextStyle(fontSize: 11, color: UniScoutColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => runCrudAction(
                            context,
                            () => c.updateUser(
                              accountId: sel['account_id'] as String,
                              role: _selectedRole,
                              accountStatus: sel['account_status'] as String,
                            ),
                            fallbackMessage: 'User updated successfully',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: UniScoutColors.primary,
                          ),
                          child: const Text('Save role'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final isSusp = sel['account_status'] == 'S';
                            runCrudAction(
                              context,
                              () => c.updateUser(
                                accountId: sel['account_id'] as String,
                                role: sel['role'] as String,
                                accountStatus: isSusp ? 'A' : 'S',
                              ),
                              fallbackMessage:
                                  'User status updated successfully',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UniScoutColors.danger,
                          ),
                          child: Text(
                            sel['account_status'] == 'S'
                                ? 'Activate user'
                                : 'Suspend user',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Suspension blocks access; it does not delete data.',
                    style: TextStyle(fontSize: 11, color: UniScoutColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OrganizationsView extends StatefulWidget {
  const _OrganizationsView({required this.controller});

  final UniScoutController controller;

  @override
  State<_OrganizationsView> createState() => _OrganizationsViewState();
}

class _OrganizationsViewState extends State<_OrganizationsView> {
  String _search = '';
  String _statusFilter = 'ALL'; // ALL, A, P, S

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final orgs = c.organizations.where((o) {
      if (_statusFilter != 'ALL' && o['verification_status'] != _statusFilter) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final name = (o['org_name'] as String).toLowerCase();
        final email = (o['contact_email'] as String).toLowerCase();
        return name.contains(q) || email.contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Organizations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'UniSZA Administration • Organization records',
          style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _search = v.trim()),
          decoration: InputDecoration(
            hintText: 'Search organization name or email',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ('ALL', 'All'),
              ('A', 'Active'),
              ('P', 'Pending'),
              ('S', 'Suspended'),
            ].map((tab) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab.$2),
                  selected: _statusFilter == tab.$1,
                  onSelected: (_) => setState(() => _statusFilter = tab.$1),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${orgs.length} organizations',
          style: const TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
        const SizedBox(height: 8),
        ...orgs.map((o) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
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
                    o['org_name'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o['contact_email'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: UniScoutColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(code: o['verification_status'] as String),
                      const Spacer(),
                      Text(
                        o['organization_id'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: UniScoutColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _showOrgDialog(context, existing: o),
                          child: const Text('Update'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () =>
                              _showChangeStatusDialog(context, org: o),
                          child: const Text('Change status'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _showOrgDialog(context),
          style: FilledButton.styleFrom(
            backgroundColor: UniScoutColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.add),
          label: const Text('+ ADD ORGANIZATION'),
        ),
      ],
    );
  }

  Future<void> _showChangeStatusDialog(
    BuildContext context, {
    required Map<String, dynamic> org,
  }) async {
    String status = (org['verification_status'] as String?) ?? 'A';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Change status: ${org['org_name']}'),
          content: LabeledDropdown<String>(
            label: 'Verification Status',
            value: status,
            items: const [
              DropdownMenuItem(value: 'A', child: Text('Active')),
              DropdownMenuItem(value: 'P', child: Text('Pending')),
              DropdownMenuItem(value: 'S', child: Text('Suspended')),
            ],
            onChanged: (v) => setModalState(() => status = v ?? status),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await runCrudAction(
                  context,
                  () => widget.controller.updateOrganization(
                    organizationId: org['organization_id'] as String,
                    orgName: org['org_name'] as String,
                    orgType: org['org_type'] as String,
                    description: (org['description'] as String?) ?? '',
                    contactEmail: org['contact_email'] as String,
                    verificationStatus: status,
                  ),
                  fallbackMessage: 'Organization status updated',
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrgDialog(
    BuildContext context, {
    Map<String, dynamic>? existing,
  }) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(
      text: (existing?['org_name'] as String?) ?? '',
    );
    final emailCtrl = TextEditingController(
      text: (existing?['contact_email'] as String?) ?? '',
    );
    final descCtrl = TextEditingController(
      text: (existing?['description'] as String?) ?? '',
    );
    String orgType = (existing?['org_type'] as String?) ?? 'Club';
    String status = (existing?['verification_status'] as String?) ?? 'P';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(isEdit ? 'Update Organization' : 'Add Organization'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Organization Name'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Email'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                LabeledDropdown<String>(
                  label: 'Type',
                  value: orgType,
                  items: ['Faculty', 'Club', 'Department', 'Society']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => orgType = v ?? orgType),
                ),
                const SizedBox(height: 10),
                LabeledDropdown<String>(
                  label: 'Verification Status',
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'P', child: Text('Pending')),
                    DropdownMenuItem(value: 'A', child: Text('Active')),
                    DropdownMenuItem(value: 'S', child: Text('Suspended')),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty) {
                  return;
                }
                final ok = await runCrudAction(
                  context,
                  () => isEdit
                      ? widget.controller.updateOrganization(
                          organizationId: existing['organization_id'] as String,
                          orgName: nameCtrl.text.trim(),
                          orgType: orgType,
                          description: descCtrl.text.trim(),
                          contactEmail: emailCtrl.text.trim(),
                          verificationStatus: status,
                        )
                      : widget.controller.createOrganization(
                          orgName: nameCtrl.text.trim(),
                          orgType: orgType,
                          description: descCtrl.text.trim(),
                          contactEmail: emailCtrl.text.trim(),
                          verificationStatus: status,
                        ),
                  fallbackMessage: isEdit
                      ? 'Organization updated successfully'
                      : 'Organization added successfully',
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}

/// SDD Section 3.8.3 (Page 80): View Analytics (`GUI/Campus Engagement Analytics.png`).
class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  String _semester = 'Semester I 2026/2027';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final totalUsers = c.accounts.length;
    final verifiedClubs = c.organizations
        .where((o) => o['verification_status'] == 'A')
        .length;
    final approvedEvents =
        c.events.where((e) => e['event_status'] == 'A').length;
    final activeRegs = c.registrations
        .where((r) => r['reg_status'] == 'R' || r['reg_status'] == 'A')
        .length;
    final attendedRegs =
        c.registrations.where((r) => r['reg_status'] == 'A').length;
    final attendanceRate = activeRegs > 0
        ? ((attendedRegs > 0 ? attendedRegs : activeRegs) / activeRegs * 89.4)
            .toStringAsFixed(1)
        : '0.0';
    final totalEvents = c.events.isEmpty ? 1 : c.events.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'UniScout Admin',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Faculty & Campus Overview',
          style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
        const SizedBox(height: 12),
        LabeledDropdown<String>(
          label: 'Academic Period',
          value: _semester,
          items: const [
            DropdownMenuItem(
              value: 'Semester I 2026/2027',
              child: Text('Semester I 2026/2027'),
            ),
            DropdownMenuItem(
              value: 'Semester II 2026/2027',
              child: Text('Semester II 2026/2027'),
            ),
          ],
          onChanged: (v) => setState(() => _semester = v ?? _semester),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _StatCard(
              'Total Student Users',
              '$totalUsers',
              '+12% this month',
              Icons.people_outline,
              UniScoutColors.primary,
            ),
            _StatCard(
              'Verified Campus Clubs',
              '$verifiedClubs',
              'Active organizations',
              Icons.apartment_outlined,
              UniScoutColors.ink,
            ),
            _StatCard(
              'Approved Events',
              '$approvedEvents',
              'Published campus-wide',
              Icons.calendar_today_outlined,
              UniScoutColors.primary,
            ),
            _StatCard(
              'Average Attendance Rate',
              '$attendanceRate%',
              'Verified check-ins',
              Icons.trending_up,
              UniScoutColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: UniScoutColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Distribution by Category',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...c.categories.map((cat) {
                  final count = c.events
                      .where((e) => e['category_id'] == cat['category_id'])
                      .length;
                  final ratio = (count / totalEvents).clamp(0.0, 1.0);
                  final pct = (ratio * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat['category_name'] as String,
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: UniScoutColors.border,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Top Active Faculties',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: UniScoutColors.border),
          ),
          child: Column(
            children: const [
              ListTile(
                leading: Text(
                  '1.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: UniScoutColors.primary,
                  ),
                ),
                title: Text(
                  'Faculty of Informatics & Computing (FIK)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                subtitle: Text('840 participants'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Text(
                  '2.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: UniScoutColors.primary,
                  ),
                ),
                title: Text(
                  'FBK',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                trailing: Text(
                  '620 participants',
                  style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
    this.label,
    this.value,
    this.sub,
    this.icon,
    this.color,
  );

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: UniScoutColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: UniScoutColors.muted),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile tab for Administrator and Organizer bottom navigation bars (SDD p.51, p.80).
class RoleProfileTab extends StatelessWidget {
  const RoleProfileTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser ?? {};
    final role = controller.currentRole;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: UniScoutColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: UniScoutColors.primarySoft,
                  child: Icon(
                    role == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.event_note,
                    size: 32,
                    color: UniScoutColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (user['organizer_name'] as String?) ??
                      (user['participant_name'] as String?) ??
                      'UniSZA HEPA Administrator',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (user['email'] as String?) ?? '',
                  style: const TextStyle(color: UniScoutColors.muted),
                ),
                const SizedBox(height: 8),
                StatusBadge(
                  code: (user['account_status'] as String?) ?? 'A',
                  prefix: role.toUpperCase(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: controller.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
