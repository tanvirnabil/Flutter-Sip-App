import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';

class ClarioDockNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ClarioDockNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      const _DockItem(
        icon: CupertinoIcons.circle_grid_3x3_fill,
        outlineIcon: CupertinoIcons.circle_grid_3x3,
        label: 'Dialpad',
      ),
      const _DockItem(
        icon: CupertinoIcons.person_crop_circle_fill,
        outlineIcon: CupertinoIcons.person_crop_circle,
        label: 'Contacts',
      ),
      const _DockItem(
        icon: CupertinoIcons.clock_fill,
        outlineIcon: CupertinoIcons.clock,
        label: 'History',
      ),
      const _DockItem(
        icon: CupertinoIcons.bubble_left_bubble_right_fill,
        outlineIcon: CupertinoIcons.bubble_left_bubble_right,
        label: 'Messages',
      ),
      const _DockItem(
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
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
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
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 48 : 36,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.brandPrimary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isSelected ? item.icon : item.outlineIcon,
                          size: isSelected ? 20 : 21,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: const BoxDecoration(
                                color: AppColors.brandAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.brandPrimary
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
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

// Backward compatible alias
typedef AuraDockNavBar = ClarioDockNavBar;

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
