import 'package:flutter/material.dart';

import '../models/incident_enums.dart';
import '../theme/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 48});

  final IncidentCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.tile, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(category.icon, color: AppColors.slate, size: size * 0.46, semanticLabel: category.label),
    );
  }
}