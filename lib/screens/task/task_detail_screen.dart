import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/models/task_model.dart';
import '../../widgets/dialogs/priority_picker_dialog.dart';

/// Task detail screen for viewing and editing a task
class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  final Set<int> usedPriorities;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.usedPriorities = const {},
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _selectDate() async {
    final date = await material.showDatePicker(
      context: context,
      initialDate: _task.dateTime,
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
    if (date != null) {
      // Keep the existing time
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _task.dateTime.hour,
        _task.dateTime.minute,
      );
      setState(() {
        _task = _task.copyWith(dateTime: newDateTime);
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await material.showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_task.dateTime),
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
    if (time != null) {
      // Keep the existing date
      final newDateTime = DateTime(
        _task.dateTime.year,
        _task.dateTime.month,
        _task.dateTime.day,
        time.hour,
        time.minute,
      );
      setState(() {
        _task = _task.copyWith(dateTime: newDateTime);
      });
    }
  }

  Future<void> _selectPriority() async {
    final priority = await PriorityPickerDialog.show(
      context,
      initialPriority: _task.priority,
      unavailablePriorities: widget.usedPriorities,
    );
    if (priority != null) {
      setState(() {
        _task = _task.copyWith(priority: priority);
      });
    }
  }

  void _toggleComplete() {
    setState(() {
      _task = _task.copyWith(isCompleted: !_task.isCompleted);
    });
  }

  void _deleteTask() {
    final responsive = context.responsive;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Task',
          style: TextStyle(fontSize: responsive.fontSize(mobile: 18, tablet: 20)),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: TextStyle(fontSize: responsive.fontSize(mobile: 14, tablet: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: responsive.fontSize(mobile: 14, tablet: 15)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'action': 'delete', 'task': _task});
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(mobile: 14, tablet: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveTask() {
    Navigator.pop(context, {'action': 'update', 'task': _task});
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final horizontalPadding = responsive.spacing(mobile: 24, tablet: 32, desktop: 40);
    final titleSize = responsive.fontSize(mobile: 20, tablet: 22, desktop: 24);
    final labelSize = responsive.fontSize(mobile: 15, tablet: 16, desktop: 17);
    final iconSize = responsive.spacing(mobile: 22, tablet: 24, desktop: 26);
    final checkboxSize = responsive.spacing(mobile: 28, tablet: 30, desktop: 32);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with X button
                Padding(
                  padding: EdgeInsets.all(responsive.spacing(mobile: 16, tablet: 20)),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(responsive.spacing(mobile: 8, tablet: 10)),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close, color: Colors.red, size: responsive.spacing(mobile: 20, tablet: 22)),
                    ),
                  ),
                ),
                // Task content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
                        // Checkbox and title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _toggleComplete,
                              child: Container(
                                width: checkboxSize,
                                height: checkboxSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _task.isCompleted ? AppColors.primary : const Color(0xFFE0E0E0),
                                    width: 2,
                                  ),
                                  color: _task.isCompleted ? AppColors.primary.withAlpha(25) : Colors.transparent,
                                ),
                                child: _task.isCompleted
                                    ? Icon(Icons.check, size: checkboxSize * 0.65, color: AppColors.primary)
                                    : null,
                              ),
                            ),
                            SizedBox(width: responsive.spacing(mobile: 14, tablet: 16)),
                            Expanded(
                              child: Text(
                                _task.title,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w500,
                                  color: _task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                                  decoration: _task.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(mobile: 8, tablet: 10)),
                        // Description
                        Padding(
                          padding: EdgeInsets.only(left: checkboxSize + responsive.spacing(mobile: 14, tablet: 16)),
                          child: Text(
                            _task.description ?? 'Description',
                            style: TextStyle(
                              fontSize: responsive.fontSize(mobile: 14, tablet: 15, desktop: 16),
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(mobile: 32, tablet: 40)),
                        // Task Date
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Task Date :',
                          value: _formatDate(_task.dateTime),
                          onTap: _selectDate,
                          iconSize: iconSize,
                          labelSize: labelSize,
                          responsive: responsive,
                        ),
                        SizedBox(height: responsive.spacing(mobile: 20, tablet: 24)),
                        // Task Time
                        _buildDetailRow(
                          icon: Icons.access_time_outlined,
                          label: 'Task Time :',
                          value: _formatTime(_task.dateTime),
                          onTap: _selectTime,
                          iconSize: iconSize,
                          labelSize: labelSize,
                          responsive: responsive,
                        ),
                        SizedBox(height: responsive.spacing(mobile: 20, tablet: 24)),
                        // Task Priority
                        _buildDetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Task Priority :',
                          value: _task.priority == 1 ? 'Default' : '${_task.priority}',
                          onTap: _selectPriority,
                          iconSize: iconSize,
                          labelSize: labelSize,
                          responsive: responsive,
                        ),
                        SizedBox(height: responsive.spacing(mobile: 24, tablet: 32)),
                        // Delete task
                        GestureDetector(
                          onTap: _deleteTask,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red.shade400, size: iconSize),
                              SizedBox(width: responsive.spacing(mobile: 8, tablet: 10)),
                              Text(
                                'Delete Task',
                                style: TextStyle(
                                  fontSize: labelSize,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Edit Task button
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: responsive.spacing(mobile: 16, tablet: 18)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Edit Task',
                        style: TextStyle(
                          fontSize: responsive.fontSize(mobile: 16, tablet: 17, desktop: 18),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required double iconSize,
    required double labelSize,
    required ResponsiveHelper responsive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: iconSize),
          SizedBox(width: responsive.spacing(mobile: 10, tablet: 12)),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(mobile: 14, tablet: 16),
              vertical: responsive.spacing(mobile: 8, tablet: 10),
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(mobile: 13, tablet: 14),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
