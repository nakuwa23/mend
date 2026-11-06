import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lifecycle of a report. Stored in Firestore by [name].
enum IncidentStatus {
  submitted('Submitted', 'Waiting for review'),
  inProgress('In progress', 'Work has started'),
  resolved('Resolved', 'Fixed'),
  closed('Closed', 'Duplicate or not actionable');

  const IncidentStatus(this.label, this.hint);
  final String label;
  final String hint;

  bool get isOpen => this == submitted || this == inProgress;

  Color get background => switch (this) {
        submitted => AppColors.submittedBg,
        inProgress => AppColors.progressBg,
        resolved => AppColors.resolvedBg,
        closed => AppColors.closedBg,
      };

  Color get foreground => switch (this) {
        submitted => AppColors.submittedFg,
        inProgress => AppColors.progressFg,
        resolved => AppColors.resolvedFg,
        closed => AppColors.closedFg,
      };

  static IncidentStatus fromName(String? value) =>
      IncidentStatus.values.firstWhere((s) => s.name == value, orElse: () => IncidentStatus.submitted);
}

enum IncidentCategory {
  facilities('Facilities', Icons.apartment_outlined),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_outlined),
  furniture('Furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.delete_outline),
  safety('Safety', Icons.shield_outlined);

  const IncidentCategory(this.label, this.icon);
  final String label;
  final IconData icon;

  static IncidentCategory fromName(String? value) =>
      IncidentCategory.values.firstWhere((c) => c.name == value, orElse: () => IncidentCategory.facilities);
}

enum Urgency {
  low('Low', 1),
  medium('Medium', 2),
  high('High', 3);

  const Urgency(this.label, this.weight);
  final String label;
  final int weight;

  static Urgency fromName(String? value) =>
      Urgency.values.firstWhere((u) => u.name == value, orElse: () => Urgency.medium);
}

enum UserRole {
  student,
  staff;

  static UserRole fromName(String? value) => value == 'staff' ? UserRole.staff : UserRole.student;
}

/// Buildings offered in the report form.
const List<String> kCampusBuildings = [
  'Block A',
  'Block B',
  'Library',
  'Cafeteria',
  'Residence A',
  'Residence B',
  'Sports area',
  'Outdoor / walkways',
];