import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/models/task_model.dart';
import '../dialogs/priority_picker_dialog.dart';

/// Bottom sheet for adding a new task
class AddTaskBottomSheet extends StatefulWidget {
  final Set<int> usedPriorities;

  const AddTaskBottomSheet({
    super.key,
    this.usedPriorities = const {},
  });

  static Future<TaskModel?> show(
    BuildContext context, {
    Set<int> usedPriorities = const {},
  }) {
    return showModalBottomSheet<TaskModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskBottomSheet(usedPriorities: usedPriorities),
    );
  }

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedPriority = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await material.showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await material.showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _selectPriority() async {
    final priority = await PriorityPickerDialog.show(
      context,
      initialPriority: _selectedPriority,
      unavailablePriorities: widget.usedPriorities,
    );
    if (priority != null) {
      setState(() => _selectedPriority = priority);
    }
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;

    // Combine date and time
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final task = TaskModel(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dateTime: dateTime,
      priority: _selectedPriority,
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final responsive = context.responsive;
    final padding = responsive.spacing(mobile: 24, tablet: 32, desktop: 40);
    final titleSize = responsive.fontSize(mobile: 20, tablet: 22, desktop: 24);
    final labelSize = responsive.fontSize(mobile: 14, tablet: 15, desktop: 16);
    final iconSize = responsive.spacing(mobile: 22, tablet: 24, desktop: 26);
    final iconPadding = responsive.spacing(mobile: 10, tablet: 12, desktop: 14);

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxWidth: responsive.contentMaxWidth,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Add Task',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(mobile: 20, tablet: 24)),
              // Task title input
              TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(fontSize: labelSize),
                decoration: InputDecoration(
                  hintText: 'Do math homework',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: labelSize),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(mobile: 16, tablet: 18),
                    vertical: responsive.spacing(mobile: 14, tablet: 16),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
              // Description label
              Text(
                'Description',
                style: TextStyle(
                  fontSize: labelSize,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(mobile: 8, tablet: 10)),
              // Description input
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(fontSize: labelSize),
                decoration: InputDecoration(
                  hintText: 'Add a description...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: labelSize),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(mobile: 16, tablet: 18),
                    vertical: responsive.spacing(mobile: 14, tablet: 16),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(mobile: 20, tablet: 24)),
              // Action row with icons
              Row(
                children: [
                  // Date picker icon
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: iconSize,
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(mobile: 12, tablet: 14)),
                  // Time picker icon
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time_outlined,
                        color: AppColors.textSecondary,
                        size: iconSize,
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(mobile: 12, tablet: 14)),
                  // Flag icon for priority
                  GestureDetector(
                    onTap: _selectPriority,
                    child: Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.flag_outlined,
                        color: AppColors.textSecondary,
                        size: iconSize,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Send button
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: EdgeInsets.all(responsive.spacing(mobile: 12, tablet: 14)),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(mobile: 12, tablet: 14)),
              // Selected date and time display
              Wrap(
                spacing: responsive.spacing(mobile: 16, tablet: 20),
                runSpacing: responsive.spacing(mobile: 8, tablet: 10),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: responsive.spacing(mobile: 14, tablet: 16), color: AppColors.textSecondary),
                      SizedBox(width: responsive.spacing(mobile: 4, tablet: 6)),
                      Text(
                        _formatDate(_selectedDate),
                        style: TextStyle(fontSize: responsive.fontSize(mobile: 12, tablet: 13), color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: responsive.spacing(mobile: 14, tablet: 16), color: AppColors.textSecondary),
                      SizedBox(width: responsive.spacing(mobile: 4, tablet: 6)),
                      Text(
                        _formatTime(_selectedTime),
                        style: TextStyle(fontSize: responsive.fontSize(mobile: 12, tablet: 13), color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: responsive.spacing(mobile: 14, tablet: 16), color: AppColors.textSecondary),
                      SizedBox(width: responsive.spacing(mobile: 4, tablet: 6)),
                      Text(
                        'Priority $_selectedPriority',
                        style: TextStyle(fontSize: responsive.fontSize(mobile: 12, tablet: 13), color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Today';
    if (taskDate == today.add(const Duration(days: 1))) return 'Tomorrow';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
