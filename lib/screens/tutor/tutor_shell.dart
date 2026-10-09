import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import '../shared/chat_list_screen.dart';
import 'earnings_screen.dart';
import 'tutor_dashboard_screen.dart';
import 'tutor_orders_screen.dart';
import 'tutor_profile_setup_screen.dart';

/// Bottom navigation for tutors: Dashboard, Orders, Chat, Earnings, Profile.
class TutorShell extends StatefulWidget {
  const TutorShell({super.key});

  @override
  State<TutorShell> createState() => _TutorShellState();
}

class _TutorShellState extends State<TutorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TutorDashboardScreen(onOpenTab: (i) => setState(() => _index = i)),
          const TutorOrdersScreen(),
          const ChatListScreen(),
          const EarningsScreen(),
          const TutorProfileSetupScreen(onboarding: false),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
