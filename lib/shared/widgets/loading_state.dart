import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LoadingState extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const LoadingState({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, _) {
        return Container(
          constraints: BoxConstraints(minHeight: itemHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(width: 90, height: 16),
                  _shimmerBox(width: 70, height: 20, radius: 10),
                ],
              ),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 12),
              const SizedBox(height: 8),
              _shimmerBox(width: 180, height: 12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(width: 80, height: 12),
                  _shimmerBox(width: 100, height: 24, radius: 6),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
