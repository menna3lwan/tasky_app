import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/models/task_model.dart';

/// Task card widget for displaying a task in the list
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final titleSize = responsive.fontSize(mobile: 16, tablet: 17, desktop: 18);
    final subtitleSize = responsive.fontSize(mobile: 13, tablet: 14, desktop: 15);
    final cardPadding = responsive.spacing(mobile: 16, tablet: 18, desktop: 20);
    final checkboxSize = responsive.spacing(mobile: 24, tablet: 26, desktop: 28);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.spacing(mobile: 12, tablet: 14)),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: checkboxSize,
                height: checkboxSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted ? AppColors.primary : AppColors.primary,
                    width: 2,
                  ),
                  color: task.isCompleted ? AppColors.primary : Colors.transparent,
                ),
                child: task.isCompleted
                    ? Icon(Icons.check, size: checkboxSize * 0.65, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(width: responsive.spacing(mobile: 14, tablet: 16)),
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.spacing(mobile: 4, tablet: 6)),
                  Text(
                    _formatDateTime(task.dateTime),
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: task.isOverdue ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Priority badge with flag and number
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(mobile: 10, tablet: 12),
                vertical: responsive.spacing(mobile: 8, tablet: 10),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(76)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: responsive.spacing(mobile: 16, tablet: 18),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: responsive.spacing(mobile: 4, tablet: 6)),
                  Text(
                    '${task.priority}',
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (taskDate == today) {
      return 'Today At $time';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow At $time';
    } else if (taskDate == yesterday) {
      return 'Yesterday At $time';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day} At $time';
    }
  }
}
