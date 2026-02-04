import 'package:flutter/material.dart';
import '../../../utilities/constants/app_colors.dart';
import '../../../utilities/constants/app_dimensions.dart';
import '../../../utilities/models/onboarding_model.dart';

/// Widget that displays a single onboarding page content
/// Following Single Responsibility Principle - only renders one onboarding page
class OnboardingPageContent extends StatelessWidget {
  final OnboardingModel data;

  const OnboardingPageContent({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset(
            data.imagePath,
            height: AppDimensions.onboardingImageHeight,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback placeholder if image is not found
              return Container(
                height: AppDimensions.onboardingImageHeight,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: AppDimensions.fontXXL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
            ),
            child: Text(
              data.description,
              style: const TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
