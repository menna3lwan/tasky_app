import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import '../../utilities/constants/app_assets.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/models/task_model.dart';
import '../../utilities/services/streak_service.dart';
import '../../utilities/services/task_service.dart';
import '../../widgets/bottom_sheets/add_task_bottom_sheet.dart';
import '../../widgets/cards/task_card.dart';
import '../profile/profile_screen.dart';
import '../statistics/statistics_screen.dart';
import '../task/task_detail_screen.dart';

/// Home screen displaying task list with Firestore integration
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _taskService = TaskService();
  final _streakService = StreakService();
  final _searchController = TextEditingController();

  // Filter states
  String _dateFilter = 'All';
  int? _priorityFilter; // null means all priorities
  TaskCategory? _categoryFilter; // null means all categories
  String _searchQuery = '';
  DateTime? _selectedDateFilter; // For specific date filtering

  // Store all tasks for priority tracking
  List<TaskModel> _allTasks = [];

  // Loading state
  bool _isLoading = true;

  // Streak data
  StreakData? _streakData;

  final List<String> _dateFilterOptions = ['All', 'Today', 'Upcoming', 'Completed', 'Pick Date'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final tasks = await _taskService.getTasks();
    final streakData = await _streakService.getStreakData();

    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _streakData = streakData;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
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

      // Category filter
      if (_categoryFilter != null && task.category != _categoryFilter) {
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
      if (mounted) {
        if (result.isSuccess) {
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Failed to create task'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleTaskComplete(TaskModel task) async {
    await _taskService.toggleTaskCompletion(task);
    // Update streak when task is completed
    if (!task.isCompleted) {
      await _streakService.onTaskCompleted(_allTasks);
    }
    if (mounted) {
      _loadData();
    }
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

      if (mounted) {
        _loadData();
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
                // Streak banner
                _buildStreakBanner(responsive),
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : _allTasks.isEmpty
                          ? _buildEmptyState(responsive)
                          : _buildTaskList(_allTasks, responsive),
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
          Row(
            children: [
              // Statistics button
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                ),
                icon: Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                  size: responsive.spacing(mobile: 24, tablet: 26),
                ),
                tooltip: 'Statistics',
              ),
              // Profile button
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
                icon: Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: responsive.spacing(mobile: 24, tablet: 26),
                ),
                tooltip: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(ResponsiveHelper responsive) {
    if (_streakData == null || _streakData!.currentStreak == 0) {
      return const SizedBox.shrink();
    }

    final horizontalPadding = responsive.spacing(mobile: 20, tablet: 24, desktop: 32);

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: responsive.spacing(mobile: 12, tablet: 16),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(mobile: 16, tablet: 20),
          vertical: responsive.spacing(mobile: 12, tablet: 14),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withAlpha(51),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: responsive.spacing(mobile: 28, tablet: 32),
            ),
            SizedBox(width: responsive.spacing(mobile: 12, tablet: 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_streakData!.currentStreak} Day Streak!',
                    style: TextStyle(
                      fontSize: responsive.fontSize(mobile: 16, tablet: 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Keep up the great work!',
                    style: TextStyle(
                      fontSize: responsive.fontSize(mobile: 12, tablet: 13),
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Best: ${_streakData!.longestStreak}',
              style: TextStyle(
                fontSize: responsive.fontSize(mobile: 12, tablet: 13),
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(230),
              ),
            ),
          ],
        ),
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
              onChanged: _onSearchChanged,
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date filter dropdown
                _buildFilterChip(
                  label: _dateFilter == 'Pick Date' && _selectedDateFilter != null
                      ? _formatFilterDate(_selectedDateFilter!)
                      : _dateFilter,
                  icon: Icons.calendar_today,
                  isActive: _dateFilter != 'All',
                  onTap: () => _showDateFilterMenu(responsive),
                  responsive: responsive,
                ),
                SizedBox(width: responsive.spacing(mobile: 8, tablet: 10)),
                // Priority filter
                _buildFilterChip(
                  label: _priorityFilter != null ? 'Priority $_priorityFilter' : 'Priority',
                  icon: Icons.flag_outlined,
                  isActive: _priorityFilter != null,
                  onTap: () => _showPriorityFilterMenu(responsive),
                  responsive: responsive,
                ),
                SizedBox(width: responsive.spacing(mobile: 8, tablet: 10)),
                // Category filter
                _buildFilterChip(
                  label: _categoryFilter?.label ?? 'Category',
                  icon: Icons.category_outlined,
                  isActive: _categoryFilter != null,
                  color: _categoryFilter?.color,
                  onTap: () => _showCategoryFilterMenu(responsive),
                  responsive: responsive,
                ),
                // Clear filters button
                if (_dateFilter != 'All' || _priorityFilter != null || _categoryFilter != null) ...[
                  SizedBox(width: responsive.spacing(mobile: 8, tablet: 10)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dateFilter = 'All';
                        _priorityFilter = null;
                        _categoryFilter = null;
                        _selectedDateFilter = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(mobile: 12, tablet: 14),
                        vertical: responsive.spacing(mobile: 8, tablet: 10),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withAlpha(76)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear, size: responsive.spacing(mobile: 16, tablet: 18), color: Colors.red),
                          SizedBox(width: responsive.spacing(mobile: 4)),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: responsive.fontSize(mobile: 12, tablet: 13),
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
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

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ResponsiveHelper responsive,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(mobile: 12, tablet: 14),
          vertical: responsive.spacing(mobile: 8, tablet: 10),
        ),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withAlpha(25) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? chipColor.withAlpha(128) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: responsive.spacing(mobile: 16, tablet: 18),
              color: isActive ? chipColor : AppColors.textSecondary,
            ),
            SizedBox(width: responsive.spacing(mobile: 6, tablet: 8)),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(mobile: 12, tablet: 13),
                color: isActive ? chipColor : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            SizedBox(width: responsive.spacing(mobile: 4)),
            Icon(
              Icons.keyboard_arrow_down,
              size: responsive.spacing(mobile: 16, tablet: 18),
              color: isActive ? chipColor : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDateFilterMenu(ResponsiveHelper responsive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(mobile: 16, tablet: 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(mobile: 20)),
                child: Row(
                  children: [
                    Text(
                      'Filter by Date',
                      style: TextStyle(
                        fontSize: responsive.fontSize(mobile: 18, tablet: 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(mobile: 12)),
              ..._dateFilterOptions.map((option) {
                final isSelected = _dateFilter == option;
                return ListTile(
                  leading: Icon(
                    option == 'Pick Date' ? Icons.date_range : Icons.calendar_today,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    option == 'Pick Date' && _selectedDateFilter != null && _dateFilter == 'Pick Date'
                        ? _formatFilterDate(_selectedDateFilter!)
                        : option,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (option == 'Pick Date') {
                      _pickFilterDate();
                    } else {
                      setState(() {
                        _dateFilter = option;
                        _selectedDateFilter = null;
                      });
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriorityFilterMenu(ResponsiveHelper responsive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(mobile: 16, tablet: 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(mobile: 20)),
                child: Row(
                  children: [
                    Text(
                      'Filter by Priority',
                      style: TextStyle(
                        fontSize: responsive.fontSize(mobile: 18, tablet: 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(mobile: 12)),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.textSecondary),
                title: const Text('All Priorities'),
                trailing: _priorityFilter == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _priorityFilter = null);
                },
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final priority = index + 1;
                    final isSelected = _priorityFilter == priority;
                    return ListTile(
                      leading: Icon(Icons.flag, color: _getPriorityColor(priority)),
                      title: Text(
                        'Priority $priority',
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _priorityFilter = priority);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilterMenu(ResponsiveHelper responsive) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(mobile: 16, tablet: 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(mobile: 20)),
                child: Row(
                  children: [
                    Text(
                      'Filter by Category',
                      style: TextStyle(
                        fontSize: responsive.fontSize(mobile: 18, tablet: 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(mobile: 12)),
              ListTile(
                leading: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
                title: const Text('All Categories'),
                trailing: _categoryFilter == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _categoryFilter = null);
                },
              ),
              ...TaskCategory.values.map((category) {
                final isSelected = _categoryFilter == category;
                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  title: Text(
                    category.label,
                    style: TextStyle(
                      color: isSelected ? category.color : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: category.color) : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _categoryFilter = category);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority <= 3) {
      return const Color(0xFF5F33E1);
    } else if (priority <= 6) {
      return const Color(0xFFFFA726);
    } else if (priority <= 8) {
      return const Color(0xFFFF5722);
    } else {
      return const Color(0xFFE53935);
    }
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
                _categoryFilter = null;
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
