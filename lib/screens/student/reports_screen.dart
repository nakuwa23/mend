import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_enums.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_card.dart';
import '../common/incident_details_screen.dart';

/// Browse, search and filter reports. All filter state lives in
/// [IncidentProvider], so it survives tab switches.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<IncidentProvider>().query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickCategory(IncidentProvider p) async {
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All categories'),
              trailing: p.categoryFilter == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, 'all'),
            ),
            for (final c in IncidentCategory.values)
              ListTile(
                leading: Icon(c.icon),
                title: Text(c.label),
                trailing: p.categoryFilter == c ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (choice == 'all') p.setCategoryFilter(null);
    if (choice is IncidentCategory) p.setCategoryFilter(choice);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<IncidentProvider>();
    final items = p.filtered;
    const statuses = <IncidentStatus?>[null, IncidentStatus.submitted, IncidentStatus.inProgress, IncidentStatus.resolved];
    String label(IncidentStatus? s) => switch (s) {
          null => 'All',
          IncidentStatus.submitted => 'New',
          IncidentStatus.inProgress => 'Active',
          final IncidentStatus other => other.label,
        };

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(children: [
              Row(
                children: [
                  Expanded(child: Text('Reports', style: Theme.of(context).textTheme.headlineSmall)),
                  SegmentedButton<ReportScope>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ReportScope.mine, label: Text('Mine')),
                      ButtonSegment(value: ReportScope.campus, label: Text('Campus')),
                    ],
                    selected: {p.scope},
                    onSelectionChanged: (s) => p.setScope(s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.slate,
                      selectedForegroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: p.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search title or location',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: p.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _search.clear();
                                  p.setQuery('');
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: p.categoryFilter != null,
                    backgroundColor: AppColors.peach,
                    smallSize: 10,
                    child: IconButton.filled(
                      tooltip: 'Filter by category',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.slate,
                        minimumSize: const Size(52, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _pickCategory(p),
                      icon: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in statuses) ...[
                      SelectChip(
                        label: '${label(s)}  ${p.scopedCount(s)}',
                        selected: p.statusFilter == s,
                        onTap: () => p.setStatusFilter(s),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${items.length} report${items.length == 1 ? '' : 's'}'
                      '${p.categoryFilter != null ? ' · ${p.categoryFilter!.label}' : ''} · newest first',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                  if (p.categoryFilter != null || p.statusFilter != null || p.query.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _search.clear();
                        p.clearFilters();
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ]),
          ),
          if (p.loading)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (p.error != null && p.all.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(icon: Icons.cloud_off_outlined, title: 'Couldn\'t load reports', message: p.error),
            )
          else if (items.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Nothing matches',
                message: 'Try another status, category or search term.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) =>const SizedBox(height: 10),
                itemBuilder: (context, i) => IncidentCard(
                  incident: items[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => IncidentDetailsScreen(incidentId: items[i].id)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}