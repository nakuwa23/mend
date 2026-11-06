import 'package:flutter/material.dart';

import '../core/time_format.dart';
import '../models/incident.dart';
import '../models/incident_enums.dart';
import '../theme/app_colors.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final done = incident.history;
    final upcoming = <String>[];
    if (incident.status == IncidentStatus.submitted) upcoming.addAll(['In progress', 'Resolved']);
    if (incident.status == IncidentStatus.inProgress) upcoming.add('Resolved');

    final rows = <Widget>[];
    for (var i = 0; i < done.length; i++) {
      final entry = done[i];
      final isCurrent = i == done.length - 1 && incident.status.isOpen;
      final isLast = i == done.length - 1 && upcoming.isEmpty;
      rows.add(_Row(
        dot: isCurrent ? _Dot.current : _Dot.done,
        line: !isLast,
        lineDone: !isCurrent,
        title: entry.status.label,
        subtitle: '${timestamp(entry.at)}${entry.byName.isNotEmpty ? ' · ${entry.byName}' : ''}',
        note: (entry.note.isNotEmpty && entry.note != 'Report submitted') ? entry.note : null,
      ));
    }
    for (var i = 0; i < upcoming.length; i++) {
      rows.add(_Row(
        dot: _Dot.upcoming,
        line: i < upcoming.length - 1,
        lineDone: false,
        title: upcoming[i],
        subtitle: upcoming[i] == 'Resolved' ? 'You\'ll be notified when it\'s fixed' : 'Waiting for Facilities',
        muted: true,
      ));
    }
    return Column(children: rows);
  }
}

enum _Dot { done, current, upcoming }

class _Row extends StatelessWidget {
  const _Row({
    required this.dot,
    required this.line,
    required this.lineDone,
    required this.title,
    required this.subtitle,
    this.note,
    this.muted = false,
  });

  final _Dot dot;
  final bool line;
  final bool lineDone;
  final String title;
  final String subtitle;
  final String? note;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _dotWidget(),
                if (line)
                  Expanded(
                    child: Container(width: 2, color: lineDone ? AppColors.slate : AppColors.stone),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: line ? 18 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: muted ? AppColors.muted : AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (note != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(note!, style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF3C4548))),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dotWidget() {
    switch (dot) {
      case _Dot.done:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: AppColors.slate, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      case _Dot.current:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.peach,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.progressBg, width: 4),
          ),
        );
      case _Dot.upcoming:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.ground,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF9DA3A5), width: 2),
          ),
        );
    }
  }
}