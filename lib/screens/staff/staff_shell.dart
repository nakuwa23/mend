import 'package:flutter/material.dart';

import '../../widgets/floating_nav_bar.dart';
import '../common/profile_screen.dart';
import 'staff_queue_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [StaffQueueScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        items: const [
          NavItem(icon: Icons.inbox_outlined, label: 'Queue'),
          NavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}