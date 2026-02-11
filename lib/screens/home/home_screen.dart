import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import '../../utilities/constants/app_assets.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/models/task_model.dart';
import '../../utilities/services/auth_service.dart';
import '../../utilities/services/task_service.dart';
import '../../widgets/bottom_sheets/add_task_bottom_sheet.dart';
import '../../widgets/cards/task_card.dart';
import '../auth/login_screen.dart';
import '../task/task_detail_screen.dart';

/// Home screen displaying task list with Firestore integration
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _taskService = TaskService();
  final _searchController = TextEditingController();

  // Filter states
  String _dateFilter = 'All';
  int? _priorityFilter; // null means all priorities
  String _searchQuery = '';
  DateTime? _selectedDateFilter; // For specific date filtering

  // Store all tasks for priority tracking
  List<TaskModel> _allTasks = [];

  final List<String> _dateFilterOptions = ['All', 'Today', 'Upcoming', 'Completed', 'Pick Date'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  /// Get used priorities from incomplete tasks
  Set<int> get _usedPriorities => _taskService.getUsedPriorities(_allTasks);

  /// Filter tasks based on all criteria
  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    return tasks.where((task) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!task.title.toLowerCase().contains(_searchQuery) &&
            !(task.description?.toLowerCase().contains(_searchQuery) ?? false)) {
          return false;
        }
      }

      // Date filter
      switch (_dateFilter) {
        case 'Today':
          if (!task.isToday) return false;
          break;
        case 'Upcoming':
          if (!task.isUpcoming) return false;
          break;
        case 'Completed':
          if (!task.isCompleted) return false;
          break;
        case 'Pick Date':
          if (_selectedDateFilter != null) {
            final taskDate = DateTime(
              task.dateTime.year,
              task.dateTime.month,
              task.dateTime.day,
            );
            final filterDate = DateTime(
              _selectedDateFilter!.year,
              _selectedDateFilter!.month,
              _selectedDateFilter!.day,
            );
            if (taskDate != filterDate) return false;
          }
          break;
        case 'All':
        default:
          break;
      }

      // Priority filter
      if (_priorityFilter != null && task.priority != _priorityFilter) {
        return false;
      }

      return true;
    }).toList()
      // Sort by priority (high first) then by date
      ..sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.dateTime.compareTo(b.dateTime);
      });
  }

  Future<void> _addTask(Set<int> usedPriorities) async {
    final task = await AddTaskBottomSheet.show(context, usedPriorities: usedPriorities);
    if (task != null) {
      final result = await _taskService.createTask(task);
      if (mounted && !result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to create task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskComplete(TaskModel task) async {
    await _taskService.toggleTaskCompletion(task);
  }

  Future<void> _openTaskDetail(TaskModel task, Set<int> usedPriorities) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          usedPriorities: usedPriorities,
        ),
      ),
    );

    if (result != null && mounted) {
      final action = result['action'] as String;
      final updatedTask = result['task'] as TaskModel;

      if (action == 'delete') {
        if (updatedTask.id != null) {
          await _taskService.deleteTask(updatedTask.id!);
        }
      } else if (action == 'update') {
        await _taskService.updateTask(updatedTask);
      }
    }
  }

  Future<void> _pickFilterDate() async {
    final date = await material.showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
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
    if (date != null && mounted) {
      setState(() {
        _selectedDateFilter = date;
        _dateFilter = 'Pick Date';
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(responsive),
                // Content with StreamBuilder for real-time updates
                Expanded(
                  child: StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getTasksStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: responsive.iconSize * 2, color: Colors.red),
                              SizedBox(height: responsive.spacing(mobile: 16)),
                              Text('Error: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }

                      final tasks = snapshot.data ?? [];
                      _allTasks = tasks; // Store for priority tracking

                      if (tasks.isEmpty) {
                        return _buildEmptyState(responsive);
                      }

                      return _buildTaskList(tasks, responsive);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(_usedPriorities),
        backgroundColor: AppColors.textPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(ResponsiveHelper responsive) {
    final titleSize = responsive.fontSize(mobile: 28, tablet: 32, desktop: 36);
    final logoutSize = responsive.fontSize(mobile: 14, tablet: 15, desktop: 16);
    final horizontalPadding = responsive.spacing(mobile: 20, tablet: 24, desktop: 32);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: responsive.spacing(mobile: 16, tablet: 20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
              children: const [
                TextSpan(text: 'Taskat', style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'k', style: TextStyle(color: AppColors.splashYellow)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _logout,
            child: Row(
              children: [
                Icon(Icons.logout, color: AppColors.primary, size: responsive.spacing(mobile: 20, tablet: 22, desktop: 24)),
                SizedBox(width: responsive.spacing(mobile: 4, tablet: 6)),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: logoutSize,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveHelper responsive) {
    final imageHeight = responsive.responsive<double>(mobile: 200, tablet: 250, desktop: 300);
    final titleSize = responsive.fontSize(mobile: 20, tablet: 22, desktop: 24);
    final subtitleSize = responsive.fontSize(mobile: 16, tablet: 17, desktop: 18);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: responsive.spacing(mobile: 40, tablet: 60, desktop: 80)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.emptyTasks,
              height: imageHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: imageHeight * 0.8,
                  width: imageHeight * 1.1,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: responsive.responsive<double>(mobile: 80, tablet: 100, desktop: 120),
                        color: AppColors.primary.withAlpha(128),
                      ),
                      SizedBox(height: responsive.spacing(mobile: 16)),
                      Text(
                        'No tasks yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: responsive.fontSize(mobile: 14, tablet: 16)),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: responsive.spacing(mobile: 40, tablet: 48)),
            Text(
              'What do you want to do today?',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.spacing(mobile: 12, tablet: 16)),
            Text(
              'Tap + to add your tasks',
              style: TextStyle(fontSize: subtitleSize, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> allTasks, ResponsiveHelper responsive) {
    final filteredTasks = _filterTasks(allTasks);
    final pendingTasks = filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();
    final usedPriorities = _usedPriorities;
    final horizontalPadding = responsive.spacing(mobile: 20, tablet: 24, desktop: 32);
    final fontSize = responsive.fontSize(mobile: 14, tablet: 15, desktop: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: fontSize),
              decoration: InputDecoration(
                hintText: 'Search for your task...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: fontSize),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(mobile: 16, tablet: 20),
                  vertical: responsive.spacing(mobile: 14, tablet: 16),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(mobile: 12, tablet: 16)),
        // Filters row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              // Date filter dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(mobile: 12, tablet: 14),
                    vertical: responsive.spacing(mobile: 4, tablet: 6),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _dateFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      isDense: true,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: AppColors.textPrimary,
                      ),
                      items: _dateFilterOptions.map((option) {
                        String displayText = option;
                        // Show selected date for "Pick Date" option
                        if (option == 'Pick Date' && _selectedDateFilter != null && _dateFilter == 'Pick Date') {
                          displayText = _formatFilterDate(_selectedDateFilter!);
                        }
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Row(
                            children: [
                              Icon(
                                option == 'Pick Date' ? Icons.date_range : Icons.calendar_today,
                                size: responsive.spacing(mobile: 16, tablet: 18),
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: responsive.spacing(mobile: 8)),
                              Expanded(
                                child: Text(
                                  displayText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == 'Pick Date') {
                          _pickFilterDate();
                        } else if (value != null) {
                          setState(() {
                            _dateFilter = value;
                            _selectedDateFilter = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(mobile: 12, tablet: 16)),
              // Priority filter dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(mobile: 12, tablet: 14),
                    vertical: responsive.spacing(mobile: 4, tablet: 6),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _priorityFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      isDense: true,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: AppColors.textPrimary,
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, size: responsive.spacing(mobile: 16, tablet: 18), color: AppColors.textSecondary),
                              SizedBox(width: responsive.spacing(mobile: 8)),
                              const Text('All Priorities'),
                            ],
                          ),
                        ),
                        ...List.generate(10, (index) {
                          final priority = index + 1;
                          return DropdownMenuItem<int?>(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(Icons.flag, size: responsive.spacing(mobile: 16, tablet: 18), color: AppColors.primary),
                                SizedBox(width: responsive.spacing(mobile: 8)),
                                Text('Priority $priority'),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _priorityFilter = value);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
        // Task list
        Expanded(
          child: filteredTasks.isEmpty
              ? _buildNoResultsState(responsive)
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pending tasks
                      ...pendingTasks.map((task) => TaskCard(
                            task: task,
                            onTap: () => _openTaskDetail(task, usedPriorities),
                            onToggleComplete: () => _toggleTaskComplete(task),
                          )),
                      // Completed section
                      if (completedTasks.isNotEmpty && _dateFilter != 'Completed') ...[
                        SizedBox(height: responsive.spacing(mobile: 8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(mobile: 12, tablet: 14),
                            vertical: responsive.spacing(mobile: 6, tablet: 8),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(fontSize: responsive.fontSize(mobile: 12, tablet: 13), color: AppColors.textSecondary),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(mobile: 12, tablet: 14)),
                        ...completedTasks.map((task) => TaskCard(
                              task: task,
                              onTap: () => _openTaskDetail(task, usedPriorities),
                              onToggleComplete: () => _toggleTaskComplete(task),
                            )),
                      ],
                      // Show completed tasks when filter is "Completed"
                      if (_dateFilter == 'Completed')
                        ...completedTasks.map((task) => TaskCard(
                              task: task,
                              onTap: () => _openTaskDetail(task, usedPriorities),
                              onToggleComplete: () => _toggleTaskComplete(task),
                            )),
                      SizedBox(height: responsive.spacing(mobile: 80, tablet: 100)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState(ResponsiveHelper responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: responsive.responsive<double>(mobile: 64, tablet: 72, desktop: 80),
            color: AppColors.textHint,
          ),
          SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: responsive.fontSize(mobile: 16, tablet: 18),
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacing(mobile: 8, tablet: 12)),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _dateFilter = 'All';
                _priorityFilter = null;
                _selectedDateFilter = null;
              });
            },
            child: Text(
              'Clear filters',
              style: TextStyle(fontSize: responsive.fontSize(mobile: 14, tablet: 15)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFilterDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) return 'Today';
    if (selectedDate == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (selectedDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
