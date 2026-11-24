import 'package:flutter/material.dart';
import 'screens/admin_screens.dart';
import 'screens/auth_screen.dart';
import 'screens/organizer_screens.dart';
import 'screens/participant_screens.dart';
import 'services/api_service.dart';
import 'widgets/shared_widgets.dart';

void main() {
  runApp(const UniScoutApp());
}

/// Root UniScout Flutter Mobile Application wired to MySQL Workbench (`uniscout_db`).
class UniScoutApp extends StatefulWidget {
  const UniScoutApp({super.key, this.skipNetworkOnInit = false});

  final bool skipNetworkOnInit;

  @override
  State<UniScoutApp> createState() => _UniScoutAppState();
}

class _UniScoutAppState extends State<UniScoutApp> {
  late final UniScoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UniScoutController(skipNetworkOnInit: widget.skipNetworkOnInit);
    if (!widget.skipNetworkOnInit) {
      _controller.refreshFromServer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'UniScout',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: UniScoutColors.primary,
              surface: UniScoutColors.surface,
            ),
            scaffoldBackgroundColor: UniScoutColors.background,
          ),
          home: _controller.currentUser == null
              ? AuthScreen(controller: _controller)
              : _MainShell(controller: _controller),
        );
      },
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({required this.controller});

  final UniScoutController controller;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _tabIndex = 0;
  String _lastRole = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final role = c.currentRole;
    if (role != _lastRole) {
      _lastRole = role;
      _tabIndex = 0;
    }

    final tabs = switch (role) {
      'organizer' => [
          ('My Events', Icons.event_note_outlined, OrganizerEventsTab(controller: c)),
          ('All Events', Icons.explore_outlined, ExploreEventsTab(controller: c)),
          ('Alerts', Icons.notifications_outlined, NotificationsTab(controller: c)),
        ],
      'admin' => [
          ('Approvals', Icons.fact_check_outlined, AdminApprovalsTab(controller: c)),
          ('Manage', Icons.manage_accounts_outlined, AdminManagementTab(controller: c)),
          ('Analytics', Icons.bar_chart_outlined, AdminAnalyticsTab(controller: c)),
          ('Events', Icons.event_outlined, OrganizerEventsTab(controller: c)),
        ],
      _ => [
          ('Explore', Icons.explore_outlined, ExploreEventsTab(controller: c)),
          ('Passes', Icons.confirmation_number_outlined, TicketsAndBookmarksTab(controller: c)),
          (
            'Alerts',
            Icons.notifications_outlined,
            NotificationsTab(controller: c),
          ),
          ('Profile', Icons.person_outline, ParticipantProfileTab(controller: c)),
        ],
    };

    final safeIdx = _tabIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'UniScout',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Switch Demo Role',
              onSelected: c.switchDemoRole,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'participant', child: Text('Role: Participant')),
                PopupMenuItem(value: 'organizer', child: Text('Role: Organizer')),
                PopupMenuItem(value: 'admin', child: Text('Role: Administrator')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: UniScoutColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        color: UniScoutColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        size: 16, color: UniScoutColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync with MySQL Workbench',
            onPressed: c.isLoading ? null : c.refreshFromServer,
            icon: c.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: c.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          SqlTraceBanner(controller: c),
          Expanded(child: tabs[safeIdx].$3),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIdx,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: tabs.map((t) {
          final unread = t.$1 == 'Alerts' ? c.unreadNotificationCount : 0;
          return NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: Icon(t.$2),
            ),
            label: t.$1,
          );
        }).toList(),
      ),
    );
  }
}
