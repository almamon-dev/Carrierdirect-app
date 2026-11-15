import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class TimelineMilestone {
  final String title;
  final String time;
  final String state; // 'done', 'current', 'pending'

  const TimelineMilestone({
    required this.title,
    required this.time,
    required this.state,
  });
}

class TripProgressTimeline extends StatelessWidget {
  final List<TimelineMilestone> milestones;
  final bool showHeader;

  const TripProgressTimeline({
    super.key,
    required this.milestones,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Progress',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Live Status',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
        ],

        ...List.generate(milestones.length, (idx) {
          final m = milestones[idx];
          final isDone = m.state == 'done';
          final isCurrent = m.state == 'current';
          final isPending = m.state == 'pending';
          final isLast = idx == milestones.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Milestone Node & Vertical Connecting Line
                Column(
                  children: [
                    if (isDone)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      )
                    else if (isCurrent)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFF7ED),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                      ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDone
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Milestone Title and Timestamp
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            m.title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : (isDone
                                        ? FontWeight.w600
                                        : FontWeight.w500),
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isPending
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          m.time,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isPending
                                ? AppColors.textMuted
                                : (isCurrent
                                      ? AppColors.primary
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
