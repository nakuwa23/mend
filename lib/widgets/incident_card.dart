import 'package:flutter/material.dart';

import '../core/time_format.dart';
import '../models/incident.dart';
import '../theme/app_colors.dart';
import 'category_icon.dart';
import 'status_pill.dart';

/// List row for a report, used on the home, browse and staff screens.
class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.showUrgency = false,
  });

  final Incident incident;
  final VoidCallback onTap;
  final bool showUrgency;

  @override
  Widget build(BuildContext context) {
    final overdue = incident.isOverdue();
    final meta = showUrgency
        ? '${incident.location} · ${incident.affectedCount} affected · ${incident.urgency.label}'
        : '${incident.location} · ${timeAgo(incident.createdAt)}';

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: overdue && showUrgency ? const Color(0xFFE8A68C) : AppColors.line,
          width: overdue && showUrgency ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CategoryIcon(incident.category, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 3),
                    if (showUrgency && overdue)
                      Row(children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.danger),
                        const SizedBox(width: 4),
                        Text('Open ${timeAgo(incident.createdAt).replaceAll(' ago', '')} · over 48 h',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger)),
                      ])
                    else
                      Row(children: [
                        const Icon(Icons.people_outline, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text('${incident.affectedCount} affected',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(incident.status),
            ],
          ),
        ),
      ),
    );
  }
}