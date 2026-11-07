import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/time_format.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_card.dart';
import '../common/incident_details_screen.dart';
import 'report_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSeeAll, required this.onReport});

  final VoidCallback onSeeAll;
  final VoidCallback onReport;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  void _open(BuildContext context, Incident i) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: i.id)));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final incidents = context.watch<IncidentProvider>();
    final known = incidents.knownIssue;
    final mine = incidents.mine.take(3).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text(DateFormat('EEEE, d MMM').format(DateTime.now()),
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text('${_greeting()}, ${user?.firstName ?? ''}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          if (known != null) ...[
            _KnownIssueBanner(incident: known, onTap: () => _open(context, known)),
            const SizedBox(height: 16),
          ],
          _SummaryCard(incidents: incidents, onSeeAll: onSeeAll),
          const SizedBox(height: 24),
          Text('Quick report', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (final c in IncidentCategory.values)
                _QuickTile(
                  category: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ReportFormScreen(initialCategory: c)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SectionHeader('My recent reports', actionLabel: mine.isEmpty ? null : 'See all', onAction: onSeeAll),
          const SizedBox(height: 4),
          if (incidents.loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (mine.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: 'See something broken on campus? Report it in under a minute.',
              action: FilledButton(onPressed: onReport, child: const Text('Report an issue')),
            )
          else
            for (final i in mine) ...[
              IncidentCard(incident: i, onTap: () => _open(context, i)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _KnownIssueBanner extends StatelessWidget {
  const _KnownIssueBanner({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.progressBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(incident.category.icon, color: const Color(0xFF7A3A14), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Known issue · ${incident.category.label}, ${incident.building}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7A3A14))),
                    const SizedBox(height: 1),
                    Text('${incident.affectedCount} affected · tap "Me too" instead of reporting again',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A3A14))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7A3A14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.incidents, required this.onSeeAll});

  final IncidentProvider incidents;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final submitted = incidents.mineCount(IncidentStatus.submitted);
    final progress = incidents.mineCount(IncidentStatus.inProgress);
    final resolved = incidents.mineCount(IncidentStatus.resolved);
    final total = submitted + progress + resolved;
    final latest = incidents.latestOfMine;

    Widget stat(Color dot, String label, int n) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onDarkMuted)),
              ]),
              const SizedBox(height: 2),
              Text('$n',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 20)),
            ],
          ),
        );

    Widget bar(int n, Color c) =>
        n == 0 ? const SizedBox.shrink() : Expanded(flex: n, child: Container(height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.slate, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My open reports', style: TextStyle(fontSize: 13, color: AppColors.onDarkMuted)),
                    const SizedBox(height: 4),
                    Text('${incidents.mineOpenCount}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: Colors.white, fontSize: 40, height: 1)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(foregroundColor: AppColors.peach),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0)
            Row(children: [
              bar(submitted, const Color(0xFF8FB4F0)),
              if (submitted > 0 && progress + resolved > 0) const SizedBox(width: 4),
              bar(progress, AppColors.peach),
              if (progress > 0 && resolved > 0) const SizedBox(width: 4),
              bar(resolved, const Color(0xFF7CC6A4)),
            ])
          else
            Container(height: 8, decoration: BoxDecoration(color: AppColors.slateSoft, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Row(children: [
            stat(const Color(0xFF8FB4F0), 'Submitted', submitted),
            stat(AppColors.peach, 'In progress', progress),
            stat(const Color(0xFF7CC6A4), 'Resolved', resolved),
          ]),
          if (latest != null && latest.history.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.slateSoft, height: 1),
            const SizedBox(height: 12),
            Text(
              'Latest: "${latest.title}" is ${latest.status.label.toLowerCase()} · ${timeAgo(latest.updatedAt)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.onDarkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.category, required this.onTap});

  final IncidentCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(category.icon, color: AppColors.slate, size: 22),
              const SizedBox(height: 8),
              Text(category.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}