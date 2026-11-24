import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// Member 4 CRUD (Process 5.1-5.3): Event Approvals (`GUI/Event Approvals.png`).
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
    final filtered = widget.controller.events
        .where((e) => e['event_status'] == _statusTab)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ('P', 'Pending'),
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
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No events in this status tab.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final e = filtered[i];
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
                                  '${e['event_id']} · ${e['org_name']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
                              '${e['start_datetime']} · ${e['location']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: UniScoutColors.muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => runCrudAction(
                                    context,
                                    () => widget.controller.reviewEvent(
                                      eventId: e['event_id'] as String,
                                      status: 'R',
                                      remarks: 'Rejected during HEPA review',
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: UniScoutColors.danger,
                                  ),
                                  child: const Text('Reject (5.3)'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => runCrudAction(
                                      context,
                                      () => widget.controller.reviewEvent(
                                        eventId: e['event_id'] as String,
                                        status: 'A',
                                        remarks: 'Approved & published by Admin',
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: UniScoutColors.primary,
                                    ),
                                    child: const Text('Approve & Publish (5.2)'),
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
        ),
      ],
    );
  }
}

/// Member 4 CRUD (Process 8.1 & 8.2): Manage Users & Organizations.
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
              Tab(text: 'Users (8.1)'),
              Tab(text: 'Organizations (8.2)'),
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

class _UsersView extends StatelessWidget {
  const _UsersView({required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: UniScoutColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User (8.1)'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
        itemCount: controller.accounts.length,
        itemBuilder: (ctx, i) {
          final u = controller.accounts[i];
          final name = (u['participant_name'] as String?) ??
              (u['organizer_name'] as String?) ??
              'Administrator';
          final isSuspended = u['account_status'] == 'S';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                '$name (${u['account_id']})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${u['email']} · role=${u['role']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(code: u['account_status'] as String),
                  PopupMenuButton<String>(
                    onSelected: (act) {
                      if (act == 'toggle_suspend') {
                        runCrudAction(
                          context,
                          () => controller.updateUser(
                            accountId: u['account_id'] as String,
                            role: u['role'] as String,
                            accountStatus: isSuspended ? 'A' : 'S',
                          ),
                        );
                      } else if (act == 'make_organizer') {
                        runCrudAction(
                          context,
                          () => controller.updateUser(
                            accountId: u['account_id'] as String,
                            role: 'organizer',
                            accountStatus: u['account_status'] as String,
                          ),
                        );
                      } else if (act == 'delete') {
                        runCrudAction(
                          context,
                          () => controller.deleteUser(u['account_id'] as String),
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle_suspend',
                        child: Text(isSuspended
                            ? 'Activate (UPDATE)'
                            : 'Suspend (UPDATE)'),
                      ),
                      const PopupMenuItem(
                        value: 'make_organizer',
                        child: Text('Set Role: organizer (UPDATE)'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Account (DELETE)'),
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

  Future<void> _showCreateUserDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'participant';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add User (Process 8.1)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              LabeledDropdown<String>(
                label: 'Role',
                value: role,
                items: ['participant', 'organizer', 'admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setModalState(() => role = v ?? 'participant'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (emailCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                  return;
                }
                final ok = await runCrudAction(
                  context,
                  () => controller.createUser(
                    email: emailCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    role: role,
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create (INSERT)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationsView extends StatelessWidget {
  const _OrganizationsView({required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrgDialog(context),
        backgroundColor: UniScoutColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Add Org (8.2)'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
        itemCount: controller.organizations.length,
        itemBuilder: (ctx, i) {
          final o = controller.organizations[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                o['org_name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${o['organization_id']} · ${o['org_type']} · ${o['contact_email']}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(code: o['verification_status'] as String),
                  PopupMenuButton<String>(
                    onSelected: (act) {
                      if (act == 'edit') {
                        _showOrgDialog(context, existing: o);
                      } else if (act == 'approve') {
                        runCrudAction(
                          context,
                          () => controller.updateOrganization(
                            organizationId: o['organization_id'] as String,
                            orgName: o['org_name'] as String,
                            orgType: o['org_type'] as String,
                            description: (o['description'] as String?) ?? '',
                            contactEmail: o['contact_email'] as String,
                            verificationStatus: 'A',
                          ),
                        );
                      } else if (act == 'delete') {
                        runCrudAction(
                          context,
                          () => controller.deleteOrganization(
                            o['organization_id'] as String,
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'approve',
                        child: Text('Verify / Approve (UPDATE)'),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Details (UPDATE)'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Org (DELETE)'),
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
          title: Text(isEdit ? 'Edit Organization' : 'Add Organization (8.2)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Organization Name'),
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
                    DropdownMenuItem(value: 'P', child: Text('Pending (P)')),
                    DropdownMenuItem(value: 'A', child: Text('Approved (A)')),
                    DropdownMenuItem(value: 'S', child: Text('Suspended (S)')),
                    DropdownMenuItem(value: 'R', child: Text('Rejected (R)')),
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
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                  return;
                }
                final ok = await runCrudAction(
                  context,
                  () => isEdit
                      ? controller.updateOrganization(
                          organizationId: existing['organization_id'] as String,
                          orgName: nameCtrl.text.trim(),
                          orgType: orgType,
                          description: descCtrl.text.trim(),
                          contactEmail: emailCtrl.text.trim(),
                          verificationStatus: status,
                        )
                      : controller.createOrganization(
                          orgName: nameCtrl.text.trim(),
                          orgType: orgType,
                          description: descCtrl.text.trim(),
                          contactEmail: emailCtrl.text.trim(),
                          verificationStatus: status,
                        ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save (UPDATE)' : 'Create (INSERT)'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Process 8.3: Campus Engagement Analytics (`GUI/Campus Engagement Analytics.png`).
class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final approvedCount =
        controller.events.where((e) => e['event_status'] == 'A').length;
    final pendingCount =
        controller.events.where((e) => e['event_status'] == 'P').length;
    final activeRegs =
        controller.registrations.where((r) => r['reg_status'] == 'R').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Campus Engagement Analytics (Process 8.3)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _StatCard('Approved Events', '$approvedCount', UniScoutColors.primary),
            _StatCard('Pending Approvals', '$pendingCount', UniScoutColors.warning),
            _StatCard('Active Registrations', '$activeRegs', UniScoutColors.success),
            _StatCard(
              'Total Accounts',
              '${controller.accounts.length}',
              UniScoutColors.ink,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Events by Category (Live SQL Count)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...controller.categories.map((cat) {
          final count = controller.events
              .where((e) => e['category_id'] == cat['category_id'])
              .length;
          return Card(
            child: ListTile(
              title: Text(cat['category_name'] as String),
              trailing: Text(
                '$count events',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.color);

  final String label;
  final String value;
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
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: UniScoutColors.muted)),
          ],
        ),
      ),
    );
  }
}

