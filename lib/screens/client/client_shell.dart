import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import '../shared/chat_list_screen.dart';
import 'client_profile_screen.dart';
import 'my_orders_screen.dart';
import 'search_screen.dart';
import 'tutor_directory_screen.dart';

/// Bottom navigation for clients: Home, Search, Orders, Chat, Profile.
class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TutorDirectoryScreen(onOpenProfile: () => setState(() => _index = 4)),
          const SearchScreen(),
          const MyOrdersScreen(),
          const ChatListScreen(),
          const ClientProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
