import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import 'accounts_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'disputes_screen.dart';
import 'transactions_screen.dart';

/// Bottom navigation for the admin: Dashboard, Accounts, Disputes, Transactions, Profile.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AdminDashboardScreen(onOpenTab: (i) => setState(() => _index = i)),
          const AccountsScreen(),
          const DisputesScreen(),
          const TransactionsScreen(),
          const AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Disputes'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transact.'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
