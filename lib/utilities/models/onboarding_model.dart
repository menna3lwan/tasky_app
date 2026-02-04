/// Data model for onboarding page content
/// Following Single Responsibility Principle - only holds onboarding data
class OnboardingModel {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
