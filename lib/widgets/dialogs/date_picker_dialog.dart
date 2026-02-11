import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';

/// Date and Time picker helper using Flutter's built-in pickers
class DateTimePicker {
  /// Show date picker
  static Future<DateTime?> pickDate(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final date = await material.showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    return date;
  }

  /// Show time picker
  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    TimeOfDay? initialTime,
  }) async {
    final time = await material.showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    return time;
  }

  /// Show date and time picker combined
  static Future<DateTime?> pickDateTime(
    BuildContext context, {
    DateTime? initialDateTime,
  }) async {
    final now = DateTime.now();
    final initial = initialDateTime ?? now;

    // First, pick date
    final date = await material.showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return null;

    // Check if context is still mounted
    if (!context.mounted) return null;

    // Then, pick time
    final time = await material.showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return null;

    // Combine date and time
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
