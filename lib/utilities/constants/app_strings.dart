/// Application string constants following Single Responsibility Principle
/// This class is responsible only for defining text strings used throughout the app
abstract class AppStrings {
  // App name
  static const String appName = 'Tasky';

  // Onboarding strings
  static const String onboardingTitle1 = 'Manage your tasks';
  static const String onboardingDesc1 =
      'You can easily manage all of your daily tasks in DoMe for free';

  static const String onboardingTitle2 = 'Create daily routine';
  static const String onboardingDesc2 =
      'In Tasky you can create your personalized routine to stay productive';

  static const String onboardingTitle3 = 'Organize your tasks';
  static const String onboardingDesc3 =
      'You can organize your daily tasks by adding your tasks into separate categories';

  // Button strings
  static const String next = 'NEXT';
  static const String getStarted = 'GET STARTED';
  static const String login = 'Login';
  static const String register = 'Register';

  // Auth strings
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String username = 'Username';
  static const String enterUsername = 'Enter username..';
  static const String enterPassword = 'Enter password..';

  // Auth navigation strings
  static const String noAccount = "Don't have an account? ";
  static const String haveAccount = 'Already have an account? ';

  // Validation messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please Enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String usernameRequired = 'Username is required';
  static const String usernameTooShort =
      'Username must be at least 3 characters';
  static const String passwordsNotMatch = 'Passwords do not match';
}
