import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utilities/constants/app_assets.dart';

/// Loading overlay widget that shows Lottie animation
/// Can be dismissed by tapping outside or pressing back button
/// Following Single Responsibility Principle - only handles loading display
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Show loading overlay
  static void show(BuildContext context) {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayWidget(
        onDismiss: () => hide(),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide loading overlay
  static void hide() {
    if (!_isShowing) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  /// Check if loading is showing
  static bool get isShowing => _isShowing;
}

class _LoadingOverlayWidget extends StatelessWidget {
  final VoidCallback onDismiss;

  const _LoadingOverlayWidget({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onDismiss();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDismiss,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Lottie.asset(
                AppAssets.loadingAnimation,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
