import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

/// SDD Sections 3.4 & 3.6: Explore Events, Recommendations, Event Details, Passes, Bookmarks.
class ExploreEventsTab extends StatefulWidget {
  const ExploreEventsTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<ExploreEventsTab> createState() => _ExploreEventsTabState();
}

class _ExploreEventsTabState extends State<ExploreEventsTab> {
  String _search = '';
  String _selectedCat = 'ALL';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pid = c.currentParticipantId;

    final visibleEvents = c.events.where((e) {
      if (e['event_status'] != 'A') return false;
      if (_selectedCat != 'ALL' && e['category_id'] != _selectedCat) {
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
                  prefixIcon:
                      const Icon(Icons.search, color: UniScoutColors.primary),
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
                    ActionChip(
                      avatar: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: UniScoutColors.primary,
                      ),
                      label: const Text('Recommended For You'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RecommendedForYouScreen(controller: c),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: UniScoutColors.primary,
                      ),
                      label: const Text('Calendar'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CampusCalendarScreen(controller: c),
                          ),
                        );
                      },
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
              ? const Center(
                  child: Text('No approved events match your filter.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 84),
                  itemCount: visibleEvents.length,
                  itemBuilder: (ctx, idx) {
                    final evt = visibleEvents[idx];
                    final eid = evt['event_id'] as String;
                    final isBookmarked = c.bookmarks.any(
                      (b) => b['participant_id'] == pid && b['event_id'] == eid,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: UniScoutColors.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EventDetailsScreen(
                                controller: c,
                                event: evt,
                              ),
                            ),
                          );
                        },
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
                                    tooltip: 'Bookmark',
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
                              const SizedBox(height: 10),
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
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => EventDetailsScreen(
                                            controller: c,
                                            event: evt,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                    ),
                                    label: const Text('Event Details'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

/// SDD Section 3.4.1 & 3.6.1 (Pages 42 & 60): Event Details page (`GUI/Event Details.png`).
class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.controller,
    required this.event,
  });

  final UniScoutController controller;
  final Map<String, dynamic> event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _followingOrganizer = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pid = c.currentParticipantId;
    final eid = widget.event['event_id'] as String;
    final evt = c.events.firstWhere(
      (e) => e['event_id'] == eid,
      orElse: () => widget.event,
    );
    final isBookmarked = c.bookmarks.any(
      (b) => b['participant_id'] == pid && b['event_id'] == eid,
    );
    final existingReg = c.registrations
        .where(
          (r) =>
              r['participant_id'] == pid &&
              r['event_id'] == eid &&
              (r['reg_status'] == 'R' || r['reg_status'] == 'A'),
        )
        .firstOrNull;

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Event Details'),
            actions: [
              IconButton(
                tooltip: 'Bookmark',
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? UniScoutColors.primary : null,
                ),
                onPressed: () => runCrudAction(
                  context,
                  () => c.toggleBookmark(
                    participantId: pid,
                    eventId: eid,
                  ),
                  fallbackMessage: 'Event bookmarked successfully',
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: UniScoutColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: UniScoutColors.primarySoft,
                      child: Icon(
                        Icons.people,
                        size: 16,
                        color: UniScoutColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '+${evt['registered_count'] ?? 35} Students Going',
                        style: const TextStyle(
                          color: UniScoutColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Invitation link copied to clipboard!'),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: UniScoutColors.primary,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Invite'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                evt['title'] as String,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UniScoutColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: UniScoutColors.primary,
                  ),
                ),
                title: Text(
                  evt['start_datetime'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Deadline: ${evt['reg_deadline'] ?? 'TBA'}'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UniScoutColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: UniScoutColors.primary,
                  ),
                ),
                title: Text(
                  evt['location'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Faculty of Informatics & Computing (FIK)',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UniScoutColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: UniScoutColors.primary,
                  ),
                ),
                title: Text(
                  (evt['org_name'] as String?) ?? 'Informatics Club UniSZA',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Verified Organizer'),
                trailing: OutlinedButton(
                  onPressed: () {
                    setState(
                      () => _followingOrganizer = !_followingOrganizer,
                    );
                  },
                  child: Text(_followingOrganizer ? 'Following' : 'Follow'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'About Event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                evt['description'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: UniScoutColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (existingReg != null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DigitalAdmissionPassScreen(
                          controller: c,
                          registration: existingReg,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: UniScoutColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text(
                    'VIEW DIGITAL ADMISSION PASS',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await runCrudAction(
                      context,
                      () => c.registerForEvent(
                        participantId: pid,
                        eventId: eid,
                      ),
                    );
                    if (ok && context.mounted) {
                      final reg = c.registrations
                          .where(
                            (r) =>
                                r['participant_id'] == pid &&
                                r['event_id'] == eid,
                          )
                          .firstOrNull;
                      if (reg != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DigitalAdmissionPassScreen(
                              controller: c,
                              registration: reg,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: UniScoutColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'REGISTER NOW (FREE)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// SDD Section 3.6.3 (Page 66): Recommended For You screen (`GUI/Recommended For You.png`).
class RecommendedForYouScreen extends StatelessWidget {
  const RecommendedForYouScreen({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final pid = controller.currentParticipantId;
    final mySkills = controller.skills
        .where((s) => s['participant_id'] == pid)
        .map((s) => s['skill_name'] as String)
        .toList();
    final myInterests = controller.interests
        .where((i) => i['participant_id'] == pid)
        .toList();
    final interestCatIds =
        myInterests.map((i) => i['category_id'] as String).toSet();

    final approvedEvents = controller.events
        .where((e) => e['event_status'] == 'A')
        .toList();
    final matches = approvedEvents.where((e) {
      return interestCatIds.isEmpty ||
          interestCatIds.contains(e['category_id']);
    }).toList();
    final listToShow = matches.isNotEmpty ? matches : approvedEvents;

    final skillSummary = mySkills.isEmpty
        ? 'Flutter, Python & UI/UX'
        : mySkills.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommended For You',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Matched to your skills in $skillSummary',
              style: const TextStyle(fontSize: 11, color: UniScoutColors.muted),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your next great opportunity',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                '${listToShow.length} top matches',
                style: const TextStyle(
                  fontSize: 12,
                  color: UniScoutColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...listToShow.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final matchScore = [96, 94, 91, 88][idx % 4];
            final skillTag = mySkills.isNotEmpty
                ? mySkills[idx % mySkills.length]
                : 'Flutter';
            final interestTag = myInterests.isNotEmpty
                ? (myInterests[idx % myInterests.length]['interest_tag']
                    as String)
                : (e['category_name'] as String);

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
                            color: UniScoutColors.warning.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            e['category_name'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: UniScoutColors.warning,
                            ),
                          ),
                        ),
                        const Spacer(),
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
                            '$matchScore% Match',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: UniScoutColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e['start_datetime'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: UniScoutColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            'Skill: $skillTag',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: UniScoutColors.primarySoft,
                        ),
                        Chip(
                          label: Text(
                            'Interest: $interestTag',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EventDetailsScreen(
                                controller: controller,
                                event: e,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('View Match & Register'),
                      ),
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

/// SDD Section 3.4.2, 3.4.3 & 3.6.2 (Pages 45, 48, 63): My Registration & Bookmarks.
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
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Calendar'),
              Tab(text: 'My Registration'),
              Tab(text: 'Bookmarks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                CampusCalendarView(controller: controller),
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
                              side: const BorderSide(
                                color: UniScoutColors.border,
                              ),
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
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  DigitalAdmissionPassScreen(
                                                controller: controller,
                                                registration: r,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.qr_code_2,
                                          size: 16,
                                        ),
                                        label: const Text('Admission Pass'),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isCancelled)
                                        OutlinedButton(
                                          onPressed: () =>
                                              _showCancelRegistrationSheet(
                                            context,
                                            registration: r,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                UniScoutColors.danger,
                                          ),
                                          child:
                                              const Text('Cancel Registration'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                // SDD Page 63: Bookmarks layout
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Your saved events, all in one place.',
                      style: TextStyle(
                        fontSize: 13,
                        color: UniScoutColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${myBookmarks.length} saved events',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: UniScoutColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (myBookmarks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No bookmarked events')),
                      ),
                    ...myBookmarks.map((b) {
                      final evt = controller.events
                          .where((e) => e['event_id'] == b['event_id'])
                          .firstOrNull;
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
                              Text(
                                '${b['start_datetime']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: UniScoutColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b['event_title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                (b['location'] as String?) ??
                                    (evt?['location'] as String?) ??
                                    'UniSZA Kampus Gong Badak',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: UniScoutColors.muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.tonal(
                                      onPressed: evt == null
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      EventDetailsScreen(
                                                    controller: controller,
                                                    event: evt,
                                                  ),
                                                ),
                                              );
                                            },
                                      child: const Text('View event'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => runCrudAction(
                                        context,
                                        () => controller.toggleBookmark(
                                          participantId: pid,
                                          eventId: b['event_id'] as String,
                                        ),
                                        fallbackMessage:
                                            'Bookmark removed successfully',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: UniScoutColors.danger,
                                      ),
                                      child: const Text('Remove'),
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
                    const Text(
                      "Only removes the bookmark.\nYour event registrations won't be affected.",
                      style: TextStyle(
                        fontSize: 11,
                        color: UniScoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// SDD Section 3.4.2 (Page 45): Cancel Event Registration bottom sheet.
  Future<void> _showCancelRegistrationSheet(
    BuildContext context, {
    required Map<String, dynamic> registration,
  }) async {
    String reason = 'Class schedule clash';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(
                  Icons.priority_high,
                  color: UniScoutColors.danger,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cancel Event Registration?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                "Are you sure you want to cancel your seat for '${registration['event_title']}'? Cancellation is not permitted within 2 hours of the event.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: UniScoutColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              LabeledDropdown<String>(
                label: 'Reason for cancellation',
                value: reason,
                items: const [
                  DropdownMenuItem(
                    value: 'Class schedule clash',
                    child: Text('Class schedule clash'),
                  ),
                  DropdownMenuItem(
                    value: 'Personal emergency',
                    child: Text('Personal emergency'),
                  ),
                ],
                onChanged: (v) => setSheetState(() => reason = v ?? reason),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  final ok = await runCrudAction(
                    context,
                    () => controller.cancelRegistration(
                      participantId: controller.currentParticipantId,
                      eventId: registration['event_id'] as String,
                    ),
                  );
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: UniScoutColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Confirm Cancellation'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep My Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SDD Section 3.4.3 (Page 48): Digital Admission Pass (`GUI/Digital Admission Pass.png`).
class DigitalAdmissionPassScreen extends StatelessWidget {
  const DigitalAdmissionPassScreen({
    super.key,
    required this.controller,
    required this.registration,
  });

  final UniScoutController controller;
  final Map<String, dynamic> registration;

  @override
  Widget build(BuildContext context) {
    final p = controller.activeParticipant;
    final studentName = (p?['full_name'] as String?) ?? 'Adam Hariz';
    final matricNo = (p?['participant_code'] as String?) ?? '083370';

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Admission Pass')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_outlined,
                size: 16,
                color: UniScoutColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'Your spot is secured. See you there!',
                style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: UniScoutColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'UniScout',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: UniScoutColors.primary,
                        ),
                      ),
                      StatusBadge(
                        code: (registration['reg_status'] as String?) ?? 'R',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (registration['event_title'] as String?) ?? 'Campus Event',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 15,
                        color: UniScoutColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (registration['start_datetime'] as String?) ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: UniScoutColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (registration['location'] as String?) ?? 'UniSZA',
                        style: const TextStyle(
                          fontSize: 13,
                          color: UniScoutColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STUDENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: UniScoutColors.muted,
                              ),
                            ),
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MATRIC',
                              style: TextStyle(
                                fontSize: 10,
                                color: UniScoutColors.muted,
                              ),
                            ),
                            Text(
                              matricNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'REGISTRATION REFERENCE',
                    style: TextStyle(
                      fontSize: 10,
                      color: UniScoutColors.muted,
                    ),
                  ),
                  Text(
                    (registration['registration_id'] as String?) ??
                        'REG-2026-0042',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: UniScoutColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✓ Confirmed & Active',
                      style: TextStyle(
                        color: UniScoutColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: UniScoutColors.border),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.qr_code_2,
                            size: 140,
                            color: UniScoutColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan at the entrance for immediate merit &\nattendance check-in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: UniScoutColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket saved to device!'),
                  backgroundColor: UniScoutColors.success,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: UniScoutColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'SAVE TICKET',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// SDD Section 3.7 (Pages 67-69): Notification Screen (`GUI/Notification.png`).
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _filter = 'All Notifications';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final accId = c.currentAccountId;
        final mine = c.notifications.where((n) {
          if (n['account_id'] != accId) return false;
          if (_filter == 'Unread') return n['is_read'] == 'N';
          if (_filter == 'System Announcements') {
            return n['notification_type'] != 'Reminder';
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Notification')),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    'All Notifications',
                    'Unread',
                    'System Announcements',
                  ].map((tab) {
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
                    ? const Center(
                        child: Text('No notifications in this filter.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: mine.length,
                        itemBuilder: (ctx, i) {
                          final n = mine[i];
                          final isUnread = n['is_read'] == 'N';
                          final type = (n['notification_type'] as String?) ??
                              'Reminder';
                          final actionLabel = switch (type) {
                            'Reminder' => 'View Event',
                            'Deadline' => 'Register',
                            _ => 'View Ticket',
                          };
                          return Card(
                            color: isUnread
                                ? UniScoutColors.primarySoft
                                : Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: UniScoutColors.border,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            UniScoutColors.primarySoft,
                                        child: Icon(
                                          Icons.notifications_active_outlined,
                                          size: 18,
                                          color: UniScoutColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${n['title']}: ${n['message']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isUnread
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${n['sent_datetime'] ?? 'Just now'}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: UniScoutColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const SizedBox(width: 48),
                                      OutlinedButton(
                                        onPressed: () => runCrudAction(
                                          context,
                                          () => c.markNotificationRead(
                                            n['notification_id'] as String,
                                          ),
                                        ),
                                        child: const Text('Details'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: () {
                                          c.markNotificationRead(
                                            n['notification_id'] as String,
                                          );
                                          final evt = c.events
                                              .where(
                                                (e) =>
                                                    e['event_id'] ==
                                                    n['event_id'],
                                              )
                                              .firstOrNull;
                                          if (evt != null) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    EventDetailsScreen(
                                                  controller: c,
                                                  event: evt,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              UniScoutColors.primary,
                                        ),
                                        child: Text(actionLabel),
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
          ),
        );
      },
    );
  }
}

/// SDD Section 3.2 (Pages 17, 21, 24, 28): Participant Profile, Edit Profile & Skills, Manage Interests.
class ParticipantProfileTab extends StatelessWidget {
  const ParticipantProfileTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.activeParticipant;
    if (p == null) {
      return const Center(
        child: Text('Switch to a Participant account to view Profile.'),
      );
    }
    final pid = p['participant_id'] as String;
    final mySkills =
        controller.skills.where((s) => s['participant_id'] == pid).toList();
    final myInterests =
        controller.interests.where((i) => i['participant_id'] == pid).toList();
    final upcomingCount = controller.registrations
        .where((r) => r['participant_id'] == pid && r['reg_status'] == 'R')
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: UniScoutColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: UniScoutColors.primarySoft,
                  child: Text(
                    (p['full_name'] as String).substring(0, 1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: UniScoutColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  p['full_name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matric: ${p['participant_code']}',
                  style: const TextStyle(
                    color: UniScoutColors.muted,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${p['program']} • Year ${p['academic_year']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: UniScoutColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const _ProfileMetric('14', 'Events Attended'),
                    _ProfileMetric('$upcomingCount', 'Upcoming Passes'),
                    _ProfileMetric('${mySkills.length}', 'Merit Badges'),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EditProfileAndSkillsScreen(
                          controller: controller,
                          participant: p,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verified Skills',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...mySkills.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${s['skill_name']} [${s['proficiency_level']}]',
              style: const TextStyle(fontSize: 14, color: UniScoutColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interest',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ManageInterestsScreen(
                      controller: controller,
                      participantId: pid,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('CHANGE', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: myInterests
              .map(
                (i) => Chip(
                  label: Text(
                    i['interest_tag'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: UniScoutColors.primary,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: UniScoutColors.muted),
        ),
      ],
    );
  }
}

/// SDD Pages 21 & 28: Edit Profile & Skills screen (`GUI/Edit Profile & Skills.png`).
class EditProfileAndSkillsScreen extends StatefulWidget {
  const EditProfileAndSkillsScreen({
    super.key,
    required this.controller,
    required this.participant,
  });

  final UniScoutController controller;
  final Map<String, dynamic> participant;

  @override
  State<EditProfileAndSkillsScreen> createState() =>
      _EditProfileAndSkillsScreenState();
}

class _EditProfileAndSkillsScreenState
    extends State<EditProfileAndSkillsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _facultyCtrl;
  late final TextEditingController _programCtrl;
  late final TextEditingController _phoneCtrl;
  late int _year;

  @override
  void initState() {
    super.initState();
    final p = widget.participant;
    _nameCtrl = TextEditingController(text: p['full_name'] as String);
    _facultyCtrl = TextEditingController(
      text: (p['faculty'] as String?) ?? 'Faculty of Informatics & Computing',
    );
    _programCtrl = TextEditingController(
      text: (p['program'] as String?) ?? 'Mobile Computing',
    );
    _phoneCtrl = TextEditingController(
      text: (p['phone_no'] as String?) ?? '+60 12-345 6789',
    );
    _year = (p['academic_year'] as int?) ?? 3;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _facultyCtrl.dispose();
    _programCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final p = widget.participant;
    final ok = await runCrudAction(
      context,
      () => widget.controller.updateProfile(
        participantId: p['participant_id'] as String,
        fullName: _nameCtrl.text.trim(),
        participantCode: p['participant_code'] as String,
        faculty: _facultyCtrl.text.trim(),
        program: _programCtrl.text.trim(),
        academicYear: _year,
        phoneNo: _phoneCtrl.text.trim(),
      ),
      fallbackMessage: 'Profile updated successfully',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pid = widget.participant['participant_id'] as String;

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final mySkills =
            c.skills.where((s) => s['participant_id'] == pid).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile & Skills')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: UniScoutColors.primarySoft,
                    child: Icon(
                      Icons.person,
                      color: UniScoutColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameCtrl.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${widget.participant['participant_code']} • UniSZA student',
                        style: const TextStyle(
                          fontSize: 12,
                          color: UniScoutColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _facultyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Faculty',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _programCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Program',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LabeledDropdown<int>(
                      label: 'Academic Year',
                      value: _year,
                      items: [1, 2, 3, 4]
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('Year $y'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _year = v ?? 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Competencies & Verified Skills',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...mySkills.map((s) {
                final skillName = s['skill_name'] as String;
                final currentLevel = s['proficiency_level'] as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            skillName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: UniScoutColors.danger,
                            ),
                            onPressed: () => runCrudAction(
                              context,
                              () => c.deleteSkill(
                                participantId: pid,
                                skillName: skillName,
                              ),
                              fallbackMessage: 'Skill removed successfully',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children:
                            ['Beginner', 'Intermediate', 'Advanced'].map((lvl) {
                          final selected = currentLevel == lvl;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Center(
                                  child: Text(
                                    lvl,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) => runCrudAction(
                                  context,
                                  () => c.updateSkill(
                                    participantId: pid,
                                    skillName: skillName,
                                    proficiencyLevel: lvl,
                                  ),
                                  fallbackMessage: 'Skill updated successfully',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () => _showAddSkillDialog(context, pid),
                icon: const Icon(Icons.add),
                label: const Text('+ Add New Skill'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saveChanges,
                style: FilledButton.styleFrom(
                  backgroundColor: UniScoutColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SAVE CHANGES',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddSkillDialog(BuildContext context, String pid) async {
    final skillCtrl = TextEditingController();
    String level = 'Beginner';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Add New Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skillCtrl,
                decoration: const InputDecoration(
                  labelText: 'Skill Name (e.g. Flutter)',
                ),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (skillCtrl.text.trim().isEmpty) return;
                final ok = await runCrudAction(
                  context,
                  () => widget.controller.addSkill(
                    participantId: pid,
                    skillName: skillCtrl.text.trim(),
                    proficiencyLevel: level,
                  ),
                  fallbackMessage: 'Skill added successfully',
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

/// SDD Section 3.2.3 (Page 24): Manage interests screen.
class ManageInterestsScreen extends StatelessWidget {
  const ManageInterestsScreen({
    super.key,
    required this.controller,
    required this.participantId,
  });

  final UniScoutController controller;
  final String participantId;

  static const Map<String, List<(String, String)>> _groupedTags = {
    'Technology & innovation': [
      ('CAT-1001', 'Flutter'),
      ('CAT-1001', 'AI & ML'),
      ('CAT-1002', 'Robotics'),
      ('CAT-1003', 'Cyber security'),
    ],
    'Design & careers': [
      ('CAT-1001', 'UI/UX'),
      ('CAT-1005', 'Entrepreneurship'),
      ('CAT-1005', 'Leadership'),
      ('CAT-1005', 'Career development'),
    ],
    'Campus life': [
      ('CAT-1002', 'Hackathons'),
      ('CAT-1004', 'Badminton'),
      ('CAT-1003', 'Debating'),
      ('CAT-1004', 'Volunteering'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final myInterests = controller.interests
            .where((i) => i['participant_id'] == participantId)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Manage interests')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Choose what you love',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                "I'll use these interests to personalize your event recommendations.",
                style: TextStyle(fontSize: 13, color: UniScoutColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                '${myInterests.length} interests selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: UniScoutColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ..._groupedTags.entries.map((group) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.key,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: group.value.map((pair) {
                          final catId = pair.$1;
                          final tag = pair.$2;
                          final existing = myInterests
                              .where(
                                (i) =>
                                    (i['interest_tag'] as String)
                                        .toLowerCase() ==
                                    tag.toLowerCase(),
                              )
                              .firstOrNull;
                          final selected = existing != null;
                          return FilterChip(
                            label: Text(selected ? tag : '+ $tag'),
                            selected: selected,
                            onSelected: (_) {
                              if (selected) {
                                runCrudAction(
                                  context,
                                  () => controller.deleteInterest(
                                    participantId: participantId,
                                    categoryId:
                                        existing['category_id'] as String,
                                    interestTag:
                                        existing['interest_tag'] as String,
                                  ),
                                  fallbackMessage:
                                      'Interest removed successfully',
                                );
                              } else {
                                runCrudAction(
                                  context,
                                  () => controller.addInterest(
                                    participantId: participantId,
                                    categoryId: catId,
                                    interestTag: tag,
                                  ),
                                  fallbackMessage:
                                      'Interest added successfully',
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: UniScoutColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SAVE INTERESTS',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// SDD Page 66 bottom navigation bar item: Map tab showing campus event locations.
class CampusMapTab extends StatelessWidget {
  const CampusMapTab({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    final activeEvents =
        controller.events.where((e) => e['event_status'] == 'A').toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Campus Event Map & Venues',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const Text(
          'UniSZA Gong Badak & Besut Campus Venues',
          style: TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
        const SizedBox(height: 12),
        ...activeEvents.map((e) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: UniScoutColors.primarySoft,
                child: Icon(
                  Icons.location_on,
                  color: UniScoutColors.primary,
                ),
              ),
              title: Text(
                e['location'] as String,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${e['title']}\n${e['start_datetime']}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EventDetailsScreen(
                      controller: controller,
                      event: e,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

/// Standalone Campus Calendar Screen (`Campus calendar.png`).
class CampusCalendarScreen extends StatelessWidget {
  const CampusCalendarScreen({super.key, required this.controller});

  final UniScoutController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: CampusCalendarView(controller: controller),
    );
  }
}

/// Interactive monthly Campus Calendar View matching `Campus calendar.png`.
class CampusCalendarView extends StatefulWidget {
  const CampusCalendarView({super.key, required this.controller});

  final UniScoutController controller;

  @override
  State<CampusCalendarView> createState() => _CampusCalendarViewState();
}

class _CampusCalendarViewState extends State<CampusCalendarView> {
  int _year = 2026;
  int _month = 11; // November 2026
  int _selectedDay = 17;

  static const List<String> _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonths = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _selectedDay = 1;
    });
  }

  Color? _markerColorForDay(int day) {
    if (_year == 2026 && _month == 11) {
      if (day == 17) return const Color(0xFFB45309); // Deadlines
      if (day == 18 || day == 24) return UniScoutColors.primary; // Events
      if (day == 20 || day == 27) return const Color(0xFF0D9488); // Societies
      if (day == 23) return const Color(0xFF9333EA); // Academic
    }
    // Check live controller events matching this date
    final prefix =
        '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final hasEvent = widget.controller.events.any(
      (e) => ((e['start_datetime'] as String?) ?? '').startsWith(prefix),
    );
    if (hasEvent) return UniScoutColors.primary;
    final hasDeadline = widget.controller.events.any(
      (e) => ((e['reg_deadline'] as String?) ?? '').startsWith(prefix),
    );
    if (hasDeadline) return const Color(0xFFB45309);
    return null;
  }

  String _weekdayShort(int year, int month, int day) {
    final dt = DateTime(year, month, day);
    // DateTime.weekday: 1=Mon .. 7=Sun
    return _weekdays[dt.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_year, _month, 1);
    final startOffset = firstOfMonth.weekday % 7; // 0 for Sunday
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    final selectedWeekday = _weekdayShort(_year, _month, _selectedDay);
    final shortMonth = _shortMonths[_month];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 90),
      children: [
        // Month header & navigation arrows
        Row(
          children: [
            Text(
              '${_monthNames[_month]} $_year',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Weekday labels: Sun Mon Tue Wed Thu Fri Sat
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekdays
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontSize: 12,
                        color: UniScoutColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Monthly day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (ctx, index) {
            final dayNum = index - startOffset + 1;
            final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
            final displayDay = inMonth
                ? dayNum
                : (dayNum < 1 ? dayNum + 30 : dayNum - daysInMonth);
            final isSelected = inMonth && dayNum == _selectedDay;
            final dotColor = inMonth ? _markerColorForDay(dayNum) : null;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: inMonth
                  ? () => setState(() => _selectedDay = dayNum)
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? UniScoutColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$displayDay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (inMonth
                                ? UniScoutColors.ink
                                : UniScoutColors.muted.withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white
                            : (dotColor ?? Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Category legend: Events, Societies, Deadlines, Academic
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendDot(color: UniScoutColors.primary, label: 'Events'),
            _LegendDot(color: Color(0xFF0D9488), label: 'Societies'),
            _LegendDot(color: Color(0xFFB45309), label: 'Deadlines'),
            _LegendDot(color: Color(0xFF9333EA), label: 'Academic'),
          ],
        ),
        const SizedBox(height: 18),
        // Upcoming header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              'From $selectedWeekday, $_selectedDay $shortMonth',
              style: const TextStyle(
                fontSize: 13,
                color: UniScoutColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Schedule cards matching Campus calendar.png
        _CalendarScheduleCard(
          dayNumber: '17',
          dayName: 'TUE',
          badgeColor: const Color(0xFFB45309),
          badgeBg: const Color(0xFFFEF3C7),
          typeLabel: 'Registration deadline',
          title: 'Cyber Security Seminar',
          subtitle: 'Closes 17 Nov • 11:59 PM',
          subtitleColor: const Color(0xFFB45309),
          onTap: () => _openFirstMatchingEvent(context, 'Cyber'),
        ),
        _CalendarScheduleCard(
          dayNumber: '18',
          dayName: 'WED',
          badgeColor: UniScoutColors.primary,
          badgeBg: const Color(0xFFF1F5F9),
          typeLabel: 'Campus event',
          title: 'UniSZA AI Hackathon 2026',
          subtitle: '18 Nov 2026 • 9:00 AM\nDewan Al-Muktafi, FIK',
          onTap: () => _openFirstMatchingEvent(context, 'Hackathon'),
        ),
        _CalendarScheduleCard(
          dayNumber: '20',
          dayName: 'FRI',
          badgeColor: const Color(0xFF0D9488),
          badgeBg: const Color(0xFFF1F5F9),
          typeLabel: 'Society session',
          title: 'PMFIK society session',
          subtitle: '20 Nov • 3:00 PM • FIK',
          onTap: () => _openFirstMatchingEvent(context, 'Flutter'),
        ),
        ...widget.controller.events
            .where((e) => e['event_status'] == 'A')
            .take(2)
            .map((e) {
          final dt = (e['start_datetime'] as String?) ?? '2026-11-24 09:00:00';
          final dayPart = dt.length >= 10 ? dt.substring(8, 10) : '24';
          return _CalendarScheduleCard(
            dayNumber: dayPart,
            dayName: 'TUE',
            badgeColor: UniScoutColors.primary,
            badgeBg: const Color(0xFFF1F5F9),
            typeLabel: 'Campus event',
            title: e['title'] as String,
            subtitle: '${e['start_datetime']} • ${e['location']}',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EventDetailsScreen(
                    controller: widget.controller,
                    event: e,
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF9333EA)),
            SizedBox(width: 8),
            Text(
              '23 Nov • Study week begins',
              style: TextStyle(
                fontSize: 13,
                color: UniScoutColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openFirstMatchingEvent(BuildContext context, String keyword) {
    final evt = widget.controller.events.firstWhere(
      (e) => (e['title'] as String)
          .toLowerCase()
          .contains(keyword.toLowerCase()),
      orElse: () => widget.controller.events.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailsScreen(
          controller: widget.controller,
          event: evt,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: UniScoutColors.muted),
        ),
      ],
    );
  }
}

class _CalendarScheduleCard extends StatelessWidget {
  const _CalendarScheduleCard({
    required this.dayNumber,
    required this.dayName,
    required this.badgeColor,
    required this.badgeBg,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.onTap,
  });

  final String dayNumber;
  final String dayName;
  final Color badgeColor;
  final Color badgeBg;
  final String typeLabel;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: UniScoutColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      dayNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: badgeColor == const Color(0xFFB45309)
                            ? badgeColor
                            : UniScoutColors.ink,
                      ),
                    ),
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor == const Color(0xFFB45309)
                            ? badgeColor
                            : UniScoutColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor ?? UniScoutColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

