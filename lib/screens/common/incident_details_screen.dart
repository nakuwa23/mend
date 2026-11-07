import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/time_format.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/status_timeline.dart';
import '../staff/staff_queue_screen.dart';

/// Shared by students and staff. 
class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  Future<void> _confirmDelete(BuildContext context, Incident incident) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('It will be removed for everyone. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final provider = context.read<IncidentProvider>();
    final ok = await provider.delete(incident);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showMessage(context, 'Report deleted.');
    } else {
      showMessage(context, provider.error ?? 'Couldn\'t delete the report.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final auth = context.watch<AuthProvider>();
    final incident = provider.byId(incidentId);
    final me = auth.user;

    if (incident == null || me == null) {
      return Scaffold(
        appBar: AppBar(),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.search_off,
                title: 'Report not found',
                message: 'It may have been deleted.',
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('#${incident.id.substring(0, 6).toUpperCase()}',
            style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        actions: [
          if (provider.canDelete(incident))
            IconButton(
              tooltip: 'Delete report',
              icon: const Icon(Icons.delete_outline),
              onPressed: provider.busy ? null : () => _confirmDelete(context, incident),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (incident.photoUrls.isNotEmpty) ...[
            _PhotoGallery(urls: incident.photoUrls),
            const SizedBox(height: 18),
          ],
          Wrap(spacing: 8, runSpacing: 8, children: [
            StatusPill(incident.status),
            TagPill(incident.category.label),
            TagPill(incident.urgency.label,
                background: incident.urgency.name == 'high' ? AppColors.dangerBg : null,
                foreground: incident.urgency.name == 'high' ? AppColors.danger : null),
          ]),
          const SizedBox(height: 12),
          Text(incident.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.2)),
          const SizedBox(height: 8),
          Text(incident.description, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF3C4548))),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _MetaTile(label: 'Location', value: incident.location),
              _MetaTile(label: 'Reported', value: timestamp(incident.createdAt)),
              _MetaTile(label: 'Last update', value: timeAgo(incident.updatedAt)),
              _ReporterTile(incident: incident, viewer: me, auth: auth),
            ],
          ),
          const SizedBox(height: 24),
          Text('Progress', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          StatusTimeline(incident: incident),
          const SizedBox(height: 24),
          if (me.isStaff)
            FilledButton.icon(
              onPressed: () => showUpdateStatusSheet(context, incident),
              icon: const Icon(Icons.edit_note),
              label: const Text('Update status'),
            )
          else
            _AffectedCard(incident: incident, uid: me.uid),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ReporterTile extends StatelessWidget {
  const _ReporterTile({required this.incident, required this.viewer, required this.auth});

  final Incident incident;
  final AppUser viewer;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    if (incident.reporterId == viewer.uid) {
      return _MetaTile(label: 'Reported by', value: incident.nameHidden ? 'You (hidden)' : 'You');
    }
    if (!viewer.isStaff || !incident.nameHidden) {
      return _MetaTile(label: 'Reported by', value: incident.reporterName);
    }
    return FutureBuilder<AppUser?>(
      future: auth.service.fetchUser(incident.reporterId),
      builder: (context, snap) => _MetaTile(
        label: 'Reported by (hidden)',
        value: snap.data?.name ?? (snap.connectionState == ConnectionState.waiting ? '…' : 'Unknown'),
      ),
    );
  }
}

class _AffectedCard extends StatelessWidget {
  const _AffectedCard({required this.incident, required this.uid});

  final Incident incident;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final isReporter = incident.reporterId == uid;
    final affected = incident.isAffected(uid);
    final canToggle = !isReporter && incident.status.isOpen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.slate, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${incident.affectedCount} ${incident.affectedCount == 1 ? 'person' : 'people'} affected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  isReporter ? 'You reported this issue' : 'More people affected raises priority for staff',
                  style: const TextStyle(fontSize: 12, color: AppColors.onDarkMuted),
                ),
              ],
            ),
          ),
          if (canToggle)
            affected
                ? OutlinedButton(
                    onPressed: provider.busy ? null : () => provider.toggleAffected(incident),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.peach,
                      side: const BorderSide(color: AppColors.peach, width: 1.5),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('You\'re in'),
                  )
                : FilledButton(
                    onPressed: provider.busy ? null : () => provider.toggleAffected(incident),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.peach,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Me too'),
                  ),
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.urls});

  final List<String> urls;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                semanticLabel: 'Photo ${i + 1} attached to the report',
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: AppColors.slateSoft,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(color: AppColors.peach),
                      ),
                errorBuilder: (context, error, stack) => Container(
                  color: AppColors.slateSoft,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.onDarkMuted, size: 40),
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${_page + 1} / ${widget.urls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}