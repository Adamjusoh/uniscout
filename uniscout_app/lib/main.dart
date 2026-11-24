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

/// Root UniScout Flutter Application following the SDD Design Layout.
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

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final role = c.currentRole;
    if (role != _lastRole) {
      _lastRole = role;
      _tabIndex = 0;
    }

    // Bottom navigation layout matching SDD p.51, p.66, p.73, p.77, p.80
    final tabs = switch (role) {
      'admin' => [
          ('Approvals', Icons.fact_check_outlined, AdminApprovalsTab(controller: c)),
          ('Analytics', Icons.bar_chart_outlined, AdminAnalyticsTab(controller: c)),
          ('Management', Icons.apartment_outlined, AdminManagementTab(controller: c)),
          ('Profile', Icons.person_outline, RoleProfileTab(controller: c)),
        ],
      'organizer' => [
          ('Explore', Icons.explore_outlined, ExploreEventsTab(controller: c)),
          ('Events', Icons.calendar_today_outlined, OrganizerEventsTab(controller: c)),
          ('Map', Icons.location_on_outlined, CampusMapTab(controller: c)),
          ('Profile', Icons.person_outline, RoleProfileTab(controller: c)),
        ],
      _ => [
          ('Explore', Icons.explore_outlined, ExploreEventsTab(controller: c)),
          ('Events', Icons.calendar_today_outlined, TicketsAndBookmarksTab(controller: c)),
          ('Map', Icons.location_on_outlined, CampusMapTab(controller: c)),
          ('Profile', Icons.person_outline, ParticipantProfileTab(controller: c)),
        ],
    };

    final safeIdx = _tabIndex.clamp(0, tabs.length - 1);
    final unread = c.unreadNotificationCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Text(
              role == 'admin' ? 'UniScout Admin' : 'UniScout',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Switch Role',
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
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: UniScoutColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openNotifications(context),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          IconButton(
            tooltip: 'MySQL Setup',
            onPressed: () => showDbSettingsDialog(context, c),
            icon: Icon(
              c.isConnectedToMySql
                  ? Icons.storage_rounded
                  : Icons.settings_outlined,
              color: c.isConnectedToMySql ? UniScoutColors.success : null,
            ),
          ),
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
      body: tabs[safeIdx].$3,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: role == 'organizer' ? 'Create Campus Event' : 'Quick Action',
        backgroundColor: UniScoutColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          if (role == 'organizer') {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateEditEventScreen(controller: c),
              ),
            );
          } else if (role == 'admin') {
            setState(() => _tabIndex = 2);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RecommendedForYouScreen(controller: c),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIdx,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.$2),
                label: t.$1,
              ),
            )
            .toList(),
      ),
    );
  }
}
