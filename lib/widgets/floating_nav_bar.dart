import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NavItem {
  const NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    this.onCenterAction,
    this.centerLabel = 'New report',
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onCenterAction;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (onCenterAction != null && i == (items.length + 1) ~/ 2) {
        children.add(_CenterButton(onPressed: onCenterAction!, label: centerLabel));
      }
      children.add(_NavButton(item: items[i], selected: i == currentIndex, onTap: () => onSelect(i)));
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x33252C2E), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.peach : AppColors.onDarkMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          width: 64,
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(item.label,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, color: AppColors.ink, size: 28),
          ),
        ),
      ),
    );
  }
}