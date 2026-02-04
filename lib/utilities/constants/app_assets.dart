/// Application asset path constants following Single Responsibility Principle
/// This class is responsible only for defining asset paths used throughout the app
abstract class AppAssets {
  // Base paths
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';

  // Onboarding images
  static const String onboarding1 = '$_imagesPath/onboarding_1.png';
  static const String onboarding2 = '$_imagesPath/onboarding_2.png';
  static const String onboarding3 = '$_imagesPath/onboarding_3.png';

  // Animations
  static const String loadingAnimation = '$_iconsPath/Loading animation blue.json';
}
