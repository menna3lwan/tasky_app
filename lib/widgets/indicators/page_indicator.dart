import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';

/// A reusable page indicator widget following Single Responsibility Principle
/// This widget is responsible only for rendering page indicators
class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final Color activeColor;
  final Color inactiveColor;
  final double indicatorSize;
  final double spacing;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
    this.activeColor = AppColors.indicatorActive,
    this.inactiveColor = AppColors.indicatorInactive,
    this.indicatorSize = AppDimensions.indicatorSize,
    this.spacing = AppDimensions.indicatorSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => _buildIndicator(index == currentIndex),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: spacing / 2),
      width: isActive ? indicatorSize * 3 : indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(indicatorSize / 2),
      ),
    );
  }
}
