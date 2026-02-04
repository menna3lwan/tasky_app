import 'package:flutter/material.dart';
import '../../utilities/constants/app_assets.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../../utilities/constants/app_strings.dart';
import '../../utilities/models/onboarding_model.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/indicators/page_indicator.dart';
import '../auth/login_screen.dart';
import 'widgets/onboarding_page_content.dart';

/// Onboarding screen with multiple pages
/// Following Single Responsibility Principle - manages onboarding flow
/// Following Open/Closed Principle - easily extendable with new pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Onboarding pages data
  /// Following Dependency Inversion Principle - data can be injected/modified easily
  final List<OnboardingModel> _pages = const [
    OnboardingModel(
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      imagePath: AppAssets.onboarding1,
    ),
    OnboardingModel(
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      imagePath: AppAssets.onboarding2,
    ),
    OnboardingModel(
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      imagePath: AppAssets.onboarding3,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageContent(data: _pages[index]);
                },
              ),
            ),
            // Bottom section with indicator and button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  // Page indicator
                  PageIndicator(
                    currentIndex: _currentPage,
                    totalPages: _pages.length,
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  // Navigation button
                  PrimaryButton(
                    text: _isLastPage ? AppStrings.getStarted : AppStrings.next,
                    onPressed: _goToNextPage,
                    width: 150,
                    height: 48,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
