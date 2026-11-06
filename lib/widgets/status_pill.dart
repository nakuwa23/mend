import 'package:flutter/material.dart';

import '../models/incident_enums.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.label,
        style: TextStyle(color: status.foreground, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Neutral pill used for the category label.
class TagPill extends StatelessWidget {
  const TagPill(this.label, {super.key, this.background, this.foreground});

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFE4E4DD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground ?? const Color(0xFF333C3E), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}