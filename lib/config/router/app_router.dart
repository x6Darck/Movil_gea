import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gea_app/features/auth/presentation/screens/login_screen.dart';
import 'package:gea_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:gea_app/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:gea_app/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:gea_app/features/calendar/presentation/screens/pinned_events_screen.dart';
import 'package:gea_app/features/announcements/presentation/screens/request_announcement_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gea_app/core/network/network_providers.dart';
import 'package:gea_app/core/services/notification_service.dart';
import 'package:gea_app/core/presentation/screens/notifications_screen.dart';
import 'package:gea_app/l10n/app_localizations.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/gea_floating_nav_bar.dart';
import 'package:gea_app/features/announcements/presentation/screens/my_requests_screen.dart';
import 'package:gea_app/features/announcements/domain/entities/announcement_request.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const ProfileScreen(),
    const AnnouncementsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dio = ref.read(dioClientProvider).dio;
      NotificationService().init(dio);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().dispose();
    super.dispose();
  }

  // Pausa el sondeo de notificaciones cuando la app no está en primer plano,
  // para no generar tráfico contra el backend mientras el usuario no la usa.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final dio = ref.read(dioClientProvider).dio;
      NotificationService().resumePolling(dio);
    } else {
      NotificationService().pausePolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(authProvider, (previous, next) {
      final dio = ref.read(dioClientProvider).dio;
      if (next.user != null && previous?.user == null) {
        NotificationService().registerDevice(dio);
      } else if (next.user == null && previous?.user != null) {
        NotificationService().unregisterDevice(dio);
      }
    });

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: GeaFloatingNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        items: [
          GeaNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
            label: l10n.navCalendar,
          ),
          GeaNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.navProfile,
          ),
          GeaNavItem(
            icon: Icons.campaign_outlined,
            selectedIcon: Icons.campaign,
            label: l10n.navAnnouncements,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 
        ? FloatingActionButton.extended(
            onPressed: () {
              final authState = ref.read(authProvider);
              if (authState.user == null) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.loginRequired),
                    content: Text(l10n.loginRequiredMessage),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                      ElevatedButton(onPressed: () => context.go('/login'), child: Text(l10n.loginAction)),
                    ],
                  ),
                );
              } else {
                context.push('/request-announcement');
              }
            },
            label: Text(l10n.requestAnnouncement),
            icon: const Icon(Icons.add_comment_outlined),
            backgroundColor: AppTokens.primary,
            foregroundColor: Colors.white,
          )
        : null,
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/request-announcement',
      builder: (context, state) => RequestAnnouncementScreen(
        editingRequest: state.extra as AnnouncementRequest?,
      ),
    ),
    GoRoute(
      path: '/my-requests',
      builder: (context, state) => const MyRequestsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/eventos/fijados',
      builder: (context, state) => const PinnedEventsScreen(),
    ),
  ],
);
