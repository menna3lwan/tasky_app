import 'package:flutter/material.dart';

/// Responsive helper class for handling different screen sizes
/// Following Single Responsibility Principle
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  /// Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get screen width
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(context).size.height;

  /// Check if device is mobile
  bool get isMobile => screenWidth < mobileBreakpoint;

  /// Check if device is tablet
  bool get isTablet => screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;

  /// Check if device is desktop
  bool get isDesktop => screenWidth >= tabletBreakpoint;

  /// Check if device is in landscape mode
  bool get isLandscape => screenWidth > screenHeight;

  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: responsive<double>(
          mobile: 16,
          tablet: 24,
          desktop: 32,
        ),
        vertical: responsive<double>(
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      );

  /// Get responsive font size multiplier
  double get fontSizeMultiplier => responsive<double>(
        mobile: 1.0,
        tablet: 1.1,
        desktop: 1.2,
      );

  /// Get responsive icon size
  double get iconSize => responsive<double>(
        mobile: 24,
        tablet: 28,
        desktop: 32,
      );

  /// Get responsive button height
  double get buttonHeight => responsive<double>(
        mobile: 48,
        tablet: 52,
        desktop: 56,
      );

  /// Get responsive card padding
  EdgeInsets get cardPadding => EdgeInsets.all(
        responsive<double>(
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ),
      );

  /// Get responsive grid cross axis count
  int get gridCrossAxisCount => responsive<int>(
        mobile: 2,
        tablet: 3,
        desktop: 4,
      );

  /// Get content max width for centering on large screens
  double get contentMaxWidth => responsive<double>(
        mobile: screenWidth,
        tablet: 600,
        desktop: 800,
      );

  /// Get responsive spacing
  double spacing({double mobile = 8, double? tablet, double? desktop}) {
    return responsive<double>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get responsive font size
  double fontSize({double mobile = 14, double? tablet, double? desktop}) {
    return responsive<double>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Extension for easy access to ResponsiveHelper
extension ResponsiveExtension on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}
