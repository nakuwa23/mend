import 'package:flutter/material.dart';

import '../../widgets/floating_nav_bar.dart';
import '../common/profile_screen.dart';
import 'home_screen.dart';
import 'report_form_screen.dart';
import 'reports_screen.dart';

/// Student app: Home, Reports and Profile tabs plus the "+" report button.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  void _openReportForm() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSeeAll: () => setState(() => _index = 1), onReport: _openReportForm),
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        onCenterAction: _openReportForm,
        items: const [
          NavItem(icon: Icons.home_outlined, label: 'Home'),
          NavItem(icon: Icons.format_list_bulleted, label: 'Reports'),
          NavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}