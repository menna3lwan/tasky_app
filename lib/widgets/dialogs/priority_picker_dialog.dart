import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';

/// Priority picker dialog with 10 priority levels in a grid
/// Supports marking priorities as unavailable (used by other tasks)
class PriorityPickerDialog extends StatefulWidget {
  final int initialPriority;
  final Set<int> unavailablePriorities;

  const PriorityPickerDialog({
    super.key,
    this.initialPriority = 1,
    this.unavailablePriorities = const {},
  });

  static Future<int?> show(
    BuildContext context, {
    int initialPriority = 1,
    Set<int> unavailablePriorities = const {},
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) => PriorityPickerDialog(
        initialPriority: initialPriority,
        unavailablePriorities: unavailablePriorities,
      ),
    );
  }

  @override
  State<PriorityPickerDialog> createState() => _PriorityPickerDialogState();
}

class _PriorityPickerDialogState extends State<PriorityPickerDialog> {
  late int _selectedPriority;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialPriority;
  }

  bool _isPriorityAvailable(int priority) {
    // Current task's priority is always available (for editing)
    if (priority == widget.initialPriority) return true;
    // Check if priority is used by another incomplete task
    return !widget.unavailablePriorities.contains(priority);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Task Priority',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Info text about unavailable priorities
            if (widget.unavailablePriorities.isNotEmpty)
              const Text(
                'Grayed priorities are used by other tasks',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 20),
            // Priority grid (2 rows x 4 columns + 2)
            _buildPriorityGrid(),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedPriority),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityGrid() {
    return Column(
      children: [
        // First row: 1-4
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildPriorityItem(index + 1)),
        ),
        const SizedBox(height: 12),
        // Second row: 5-8
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildPriorityItem(index + 5)),
        ),
        const SizedBox(height: 12),
        // Third row: 9-10
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            _buildPriorityItem(9),
            const SizedBox(width: 12),
            _buildPriorityItem(10),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityItem(int priority) {
    final isSelected = _selectedPriority == priority;
    final isAvailable = _isPriorityAvailable(priority);

    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selectedPriority = priority) : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isAvailable
                  ? Colors.white
                  : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isAvailable
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFFBDBDBD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? AppColors.primary
                            : AppColors.textHint,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$priority',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isAvailable
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // Show lock icon for unavailable priorities
            if (!isAvailable)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.lock,
                  size: 12,
                  color: AppColors.textHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
