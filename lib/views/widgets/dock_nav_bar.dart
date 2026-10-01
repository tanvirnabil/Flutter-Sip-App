import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/utils/haptics.dart';

class AuraDockNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AuraDockNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _DockItem(
        icon: CupertinoIcons.circle_grid_3x3_fill,
        outlineIcon: CupertinoIcons.circle_grid_3x3,
        label: 'Dialpad',
      ),
      _DockItem(
        icon: CupertinoIcons.person_crop_circle_fill,
        outlineIcon: CupertinoIcons.person_crop_circle,
        label: 'Contacts',
      ),
      _DockItem(
        icon: CupertinoIcons.clock_fill,
        outlineIcon: CupertinoIcons.clock,
        label: 'History',
      ),
      _DockItem(
        icon: CupertinoIcons.bubble_left_bubble_right_fill,
        outlineIcon: CupertinoIcons.bubble_left_bubble_right,
        label: 'Chat',
      ),
      _DockItem(
        icon: CupertinoIcons.gear_alt_fill,
        outlineIcon: CupertinoIcons.gear_alt,
        label: 'Settings',
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.selection();
                    onTap(index);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 48 : 36,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF58220) // Orange highlight matching reference
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isSelected ? item.icon : item.outlineIcon,
                          size: isSelected ? 20 : 21,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white60 : const Color(0xFF636366)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFF58220)
                              : (isDark ? Colors.white60 : const Color(0xFF636366)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DockItem {
  final IconData icon;
  final IconData outlineIcon;
  final String label;

  const _DockItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
  });
}
