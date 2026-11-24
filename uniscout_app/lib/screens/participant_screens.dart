import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// Member 3 CRUD: Event Discovery, Registration (4.1-4.3) & Bookmarks (6.1-6.3).
class ExploreEventsTab extends StatefulWidget {
  const ExploreEventsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<ExploreEventsTab> createState() => _ExploreEventsTabState();
}

class _ExploreEventsTabState extends State<ExploreEventsTab> {
  String _search = '';
  String _selectedCat = 'ALL';
  bool _recommendedOnly = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pid = c.currentParticipantId;

    // Collect participant interest category IDs for Process 6.3 matching
    final interestCatIds = c.interests
        .where((i) => i['participant_id'] == pid)
        .map((i) => i['category_id'] as String)
        .toSet();

    final visibleEvents = c.events.where((e) {
      if (e['event_status'] != 'A') return false;
      if (_selectedCat != 'ALL' && e['category_id'] != _selectedCat) {
        return false;
      }
      if (_recommendedOnly && !interestCatIds.contains(e['category_id'])) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final title = (e['title'] as String).toLowerCase();
        final loc = (e['location'] as String).toLowerCase();
        return title.contains(q) || loc.contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search campus events...',
                  prefixIcon: const Icon(Icons.search, color: UniScoutColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: UniScoutColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Recommended For You (6.3)'),
                      selected: _recommendedOnly,
                      onSelected: (v) => setState(() => _recommendedOnly = v),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCat == 'ALL',
                      onSelected: (_) => setState(() => _selectedCat = 'ALL'),
                    ),
                    ...c.categories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(cat['category_name'] as String),
                          selected: _selectedCat == cat['category_id'],
                          onSelected: (_) => setState(
                            () => _selectedCat = cat['category_id'] as String,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visibleEvents.isEmpty
              ? const Center(child: Text('No approved events match your filter.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visibleEvents.length,
                  itemBuilder: (ctx, idx) {
                    final evt = visibleEvents[idx];
                    final eid = evt['event_id'] as String;
                    final isBookmarked = c.bookmarks.any(
                      (b) => b['participant_id'] == pid && b['event_id'] == eid,
                    );
                    final isRegistered = c.registrations.any(
                      (r) =>
                          r['participant_id'] == pid &&
                          r['event_id'] == eid &&
                          (r['reg_status'] == 'R' || r['reg_status'] == 'A'),
                    );
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: UniScoutColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${evt['category_name']} · ${evt['event_mode']}',
                                    style: const TextStyle(
                                      color: UniScoutColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Toggle Bookmark (6.1 / 6.2)',
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? UniScoutColors.primary
                                        : UniScoutColors.muted,
                                  ),
                                  onPressed: () => runCrudAction(
                                    context,
                                    () => c.toggleBookmark(
                                      participantId: pid,
                                      eventId: eid,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              evt['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${evt['start_datetime']} · ${evt['location']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: UniScoutColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              evt['description'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  '${evt['registered_count'] ?? 0} / ${evt['capacity']} seats',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: isRegistered
                                      ? null
                                      : () => runCrudAction(
                                            context,
                                            () => c.registerForEvent(
                                              participantId: pid,
                                              eventId: eid,
                                            ),
                                          ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: UniScoutColors.primary,
                                  ),
                                  child: Text(
                                    isRegistered
                                        ? 'Registered'
                                        : 'Register (INSERT 4.1)',
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

/// Member 3 CRUD: My Registrations (4.2, 4.3) & Saved Bookmarks (6.2).
class TicketsAndBookmarksTab extends StatelessWidget {
  const TicketsAndBookmarksTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final pid = controller.currentParticipantId;
    final myRegs = controller.registrations
        .where((r) => r['participant_id'] == pid)
        .toList();
    final myBookmarks = controller.bookmarks
        .where((b) => b['participant_id'] == pid)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'My Passes (4.2 / 4.3)'),
              Tab(text: 'Bookmarks (6.2)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                myRegs.isEmpty
                    ? const Center(child: Text('No registrations yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: myRegs.length,
                        itemBuilder: (ctx, i) {
                          final r = myRegs[i];
                          final isCancelled = r['reg_status'] == 'C';
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
                                        r['registration_id'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: UniScoutColors.primary,
                                        ),
                                      ),
                                      const Spacer(),
                                      StatusBadge(
                                        code: r['reg_status'] as String,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    r['event_title'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${r['start_datetime']} · ${r['location']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: UniScoutColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (!isCancelled)
                                        OutlinedButton(
                                          onPressed: () => runCrudAction(
                                            context,
                                            () => controller.cancelRegistration(
                                              participantId: pid,
                                              eventId: r['event_id'] as String,
                                            ),
                                          ),
                                          child: const Text('Cancel Seat (UPDATE)'),
                                        ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => runCrudAction(
                                          context,
                                          () => controller.cancelRegistration(
                                            participantId: pid,
                                            eventId: r['event_id'] as String,
                                            hardDelete: true,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: UniScoutColors.danger,
                                        ),
                                        child: const Text('Delete Row'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                myBookmarks.isEmpty
                    ? const Center(child: Text('No saved bookmarks yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: myBookmarks.length,
                        itemBuilder: (ctx, i) {
                          final b = myBookmarks[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                b['event_title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${b['bookmark_id']} · ${b['start_datetime']}',
                              ),
                              trailing: TextButton(
                                onPressed: () => runCrudAction(
                                  context,
                                  () => controller.toggleBookmark(
                                    participantId: pid,
                                    eventId: b['event_id'] as String,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: UniScoutColors.danger,
                                ),
                                child: const Text('Remove (DELETE)'),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Process 7.0: Manage Notification (`GUI/Notification.png`).
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final accId = widget.controller.currentAccountId;
    final mine = widget.controller.notifications.where((n) {
      if (n['account_id'] != accId) return false;
      if (_filter == 'Unread') return n['is_read'] == 'N';
      if (_filter == 'Recommendation') {
        return n['notification_type'] == 'Recommendation';
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: ['All', 'Unread', 'Recommendation'].map((tab) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab),
                  selected: _filter == tab,
                  onSelected: (_) => setState(() => _filter = tab),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: mine.isEmpty
              ? const Center(child: Text('No notifications in this filter.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mine.length,
                  itemBuilder: (ctx, i) {
                    final n = mine[i];
                    final isUnread = n['is_read'] == 'N';
                    return Card(
                      color: isUnread ? UniScoutColors.primarySoft : Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          n['title'] as String,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${n['message']}\n${n['notification_id']} · ${n['notification_type']}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (act) {
                            if (act == 'read') {
                              runCrudAction(
                                context,
                                () => widget.controller.markNotificationRead(
                                  n['notification_id'] as String,
                                ),
                              );
                            } else if (act == 'delete') {
                              runCrudAction(
                                context,
                                () => widget.controller.deleteNotification(
                                  n['notification_id'] as String,
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'read',
                              child: Text('Mark Read (UPDATE)'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete (DELETE)'),
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

/// Member 1 CRUD: Participant Profile, Interests & Skills (`GUI/My Profile.png`).
class ParticipantProfileTab extends StatelessWidget {
  const ParticipantProfileTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.activeParticipant;
    if (p == null) {
      return const Center(
        child: Text('Switch to a Participant account to manage Profile/Skills/Interests.'),
      );
    }
    final pid = p['participant_id'] as String;
    final mySkills =
        controller.skills.where((s) => s['participant_id'] == pid).toList();
    final myInterests =
        controller.interests.where((i) => i['participant_id'] == pid).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: UniScoutColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: UniScoutColors.primarySoft,
                  child: Text(
                    (p['full_name'] as String).substring(0, 1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: UniScoutColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  p['full_name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Matric: ${p['participant_code']} · Year ${p['academic_year']}',
                  style: const TextStyle(color: UniScoutColors.muted),
                ),
                Text(
                  '${p['faculty']} · ${p['program']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: UniScoutColors.muted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(context, p),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile (UPDATE 2.2)'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Verified Skills (Process 2.4)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              onPressed: () => _showAddSkillDialog(context, pid),
              icon: const Icon(Icons.add),
              label: const Text('Add Skill'),
            ),
          ],
        ),
        ...mySkills.map(
          (s) => Card(
            child: ListTile(
              title: Text(s['skill_name'] as String),
              subtitle: Text('Proficiency: ${s['proficiency_level']} · ${s['skill_id']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, color: UniScoutColors.primary),
                    tooltip: 'Update Proficiency (UPDATE)',
                    onPressed: () => _showUpdateSkillDialog(context, pid, s),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: UniScoutColors.danger),
                    tooltip: 'Delete Skill (DELETE)',
                    onPressed: () => runCrudAction(
                      context,
                      () => controller.deleteSkill(
                        participantId: pid,
                        skillName: s['skill_name'] as String,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interests (Process 2.3)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              onPressed: () => _showAddInterestDialog(context, pid),
              icon: const Icon(Icons.add),
              label: const Text('Add Interest'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: myInterests
              .map(
                (i) => Chip(
                  label: Text('${i['interest_tag']} (${i['category_name']})'),
                  backgroundColor: UniScoutColors.primarySoft,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => runCrudAction(
                    context,
                    () => controller.deleteInterest(
                      participantId: pid,
                      categoryId: i['category_id'] as String,
                      interestTag: i['interest_tag'] as String,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    Map<String, dynamic> p,
  ) async {
    final nameCtrl = TextEditingController(text: p['full_name'] as String);
    final codeCtrl = TextEditingController(text: p['participant_code'] as String);
    final facultyCtrl = TextEditingController(text: (p['faculty'] as String?) ?? '');
    final programCtrl = TextEditingController(text: (p['program'] as String?) ?? '');
    final phoneCtrl = TextEditingController(text: (p['phone_no'] as String?) ?? '');
    int year = (p['academic_year'] as int?) ?? 3;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Update Profile (Process 2.2)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Matric No.')),
                TextField(controller: facultyCtrl, decoration: const InputDecoration(labelText: 'Faculty')),
                TextField(controller: programCtrl, decoration: const InputDecoration(labelText: 'Program')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone No.')),
                const SizedBox(height: 10),
                LabeledDropdown<int>(
                  label: 'Academic Year',
                  value: year,
                  items: [1, 2, 3, 4]
                      .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                      .toList(),
                  onChanged: (v) => setModalState(() => year = v ?? 3),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final ok = await runCrudAction(
                  context,
                  () => controller.updateProfile(
                    participantId: p['participant_id'] as String,
                    fullName: nameCtrl.text.trim(),
                    participantCode: codeCtrl.text.trim(),
                    faculty: facultyCtrl.text.trim(),
                    program: programCtrl.text.trim(),
                    academicYear: year,
                    phoneNo: phoneCtrl.text.trim(),
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save (UPDATE)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSkillDialog(BuildContext context, String pid) async {
    final skillCtrl = TextEditingController();
    String level = 'Beginner';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add Skill (Process 2.4)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skillCtrl,
                decoration: const InputDecoration(labelText: 'Skill Name (e.g. Kotlin)'),
              ),
              const SizedBox(height: 12),
              LabeledDropdown<String>(
                label: 'Proficiency Level',
                value: level,
                items: ['Beginner', 'Intermediate', 'Advanced']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setModalState(() => level = v ?? 'Beginner'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (skillCtrl.text.trim().isEmpty) return;
                final ok = await runCrudAction(
                  context,
                  () => controller.addSkill(
                    participantId: pid,
                    skillName: skillCtrl.text.trim(),
                    proficiencyLevel: level,
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add (INSERT)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateSkillDialog(
    BuildContext context,
    String pid,
    Map<String, dynamic> skill,
  ) async {
    String level = skill['proficiency_level'] as String;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Update ${skill['skill_name']}'),
          content: LabeledDropdown<String>(
            label: 'Proficiency Level',
            value: level,
            items: ['Beginner', 'Intermediate', 'Advanced']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setModalState(() => level = v ?? 'Beginner'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final ok = await runCrudAction(
                  context,
                  () => controller.updateSkill(
                    participantId: pid,
                    skillName: skill['skill_name'] as String,
                    proficiencyLevel: level,
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save (UPDATE)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddInterestDialog(BuildContext context, String pid) async {
    final tagCtrl = TextEditingController();
    String catId = controller.categories.first['category_id'] as String;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add Interest (Process 2.3)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 10),
              TextField(
                controller: tagCtrl,
                decoration: const InputDecoration(labelText: 'Interest Tag (e.g. Cloud Computing)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (tagCtrl.text.trim().isEmpty) return;
                final ok = await runCrudAction(
                  context,
                  () => controller.addInterest(
                    participantId: pid,
                    categoryId: catId,
                    interestTag: tagCtrl.text.trim(),
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add (INSERT)'),
            ),
          ],
        ),
      ),
    );
  }
}

