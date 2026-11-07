import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/status_pill.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (yes == true && context.mounted) await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                InitialsAvatar(user.initials, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      TagPill(
                        user.isStaff ? 'Facilities staff' : 'Student',
                        background: user.isStaff ? AppColors.peach : null,
                        foreground: user.isStaff ? AppColors.ink : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!user.isStaff) ...[
            const SizedBox(height: 16),
            Row(children: [
              _Stat(label: 'Total reports', value: incidents.mine.length),
              const SizedBox(width: 10),
              _Stat(label: 'In progress', value: incidents.mineCount(IncidentStatus.inProgress)),
              const SizedBox(width: 10),
              _Stat(label: 'Resolved', value: incidents.mineCount(IncidentStatus.resolved)),
            ]),
          ],
          const SizedBox(height: 20),
          InfoBanner(
            icon: Icons.privacy_tip_outlined,
            child: Text(user.isStaff
                ? 'You can update statuses because an admin gave your account the staff role.'
                : 'When you hide your name on a report, other students see "Anonymous student". Staff can still see it\'s you.'),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}