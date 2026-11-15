import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadNotifications;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {
        'label': 'Dashboard',
        'icon': Icons.home_rounded,
        'outlined': Icons.home_outlined,
      },
      {
        'label': 'Shipments',
        'icon': Icons.local_shipping_rounded,
        'outlined': Icons.local_shipping_outlined,
      },
      {
        'label': 'Live Chat',
        'icon': Icons.forum_rounded,
        'outlined': Icons.forum_outlined,
      },
      {
        'label': 'Notifications',
        'icon': Icons.notifications_rounded,
        'outlined': Icons.notifications_none_rounded,
      },
      {
        'label': 'Profile',
        'icon': Icons.person_rounded,
        'outlined': Icons.person_outline_rounded,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = currentIndex == index;
              final item = navItems[index];
              final isNotif = index == 3;

              Widget iconWidget = Icon(
                isSelected
                    ? (item['icon'] as IconData)
                    : (item['outlined'] as IconData),
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.navInactive,
              );

              if (isNotif && unreadNotifications > 0) {
                iconWidget = Badge(
                  label: Text(
                    unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppColors.error,
                  child: iconWidget,
                );
              }

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconWidget,
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.navInactive,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
