import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

/// Task service class for Firestore operations
/// Path: users/{userId}/tasks/{taskId}
class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get tasks collection reference for current user
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('tasks');
  }

  /// Create a new task
  Future<TaskResult> createTask(TaskModel task) async {
    try {
      if (_userId == null) {
        return TaskResult.failure('User not logged in');
      }

      final docRef = await _tasksCollection.add(task.toFirestore());
      final createdTask = task.copyWith(id: docRef.id);

      return TaskResult.success(createdTask);
    } catch (e) {
      return TaskResult.failure('Failed to create task: ${e.toString()}');
    }
  }

  /// Get all tasks ordered by date
  Future<List<TaskModel>> getTasks() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _tasksCollection
          .orderBy('dateTime', descending: false)
          .get();
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get today's tasks
  Future<List<TaskModel>> getTodayTasks() async {
    if (_userId == null) return [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _tasksCollection
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('dateTime')
          .get();
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get completed tasks for statistics
  Future<List<TaskModel>> getCompletedTasks({int? limit}) async {
    if (_userId == null) return [];

    try {
      var query = _tasksCollection
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get tasks completed in a date range
  Future<List<TaskModel>> getTasksCompletedInRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_userId == null) return [];

    try {
      final snapshot = await _tasksCollection
          .where('isCompleted', isEqualTo: true)
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update a task
  Future<TaskResult> updateTask(TaskModel task) async {
    try {
      if (_userId == null) {
        return TaskResult.failure('User not logged in');
      }

      if (task.id == null) {
        return TaskResult.failure('Task ID is required');
      }

      await _tasksCollection.doc(task.id).update(task.toFirestore());

      return TaskResult.success(task);
    } catch (e) {
      return TaskResult.failure('Failed to update task: ${e.toString()}');
    }
  }

  /// Toggle task completion status
  Future<TaskResult> toggleTaskCompletion(TaskModel task) async {
    try {
      if (_userId == null) {
        return TaskResult.failure('User not logged in');
      }

      if (task.id == null) {
        return TaskResult.failure('Task ID is required');
      }

      final isNowCompleted = !task.isCompleted;
      final completedAt = isNowCompleted ? DateTime.now() : null;

      final updatedTask = task.copyWith(
        isCompleted: isNowCompleted,
        completedAt: completedAt,
      );

      await _tasksCollection.doc(task.id).update({
        'isCompleted': isNowCompleted,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt) : null,
      });

      // Create next occurrence for recurring tasks when completed
      if (isNowCompleted && task.recurrence != TaskRecurrence.none) {
        await _createNextOccurrence(task);
      }

      return TaskResult.success(updatedTask);
    } catch (e) {
      return TaskResult.failure('Failed to update task: ${e.toString()}');
    }
  }

  /// Create next occurrence for recurring task
  Future<void> _createNextOccurrence(TaskModel task) async {
    final nextDate = task.getNextOccurrence();
    if (nextDate == null) return;

    final newTask = TaskModel(
      title: task.title,
      description: task.description,
      dateTime: nextDate,
      priority: task.priority,
      isCompleted: false,
      category: task.category,
      recurrence: task.recurrence,
    );

    await createTask(newTask);
  }

  /// Delete a task
  Future<TaskResult> deleteTask(String taskId) async {
    try {
      if (_userId == null) {
        return TaskResult.failure('User not logged in');
      }

      await _tasksCollection.doc(taskId).delete();

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure('Failed to delete task: ${e.toString()}');
    }
  }

  /// Get used priorities (from incomplete tasks only)
  /// Returns a set of priority numbers that are currently in use
  Set<int> getUsedPriorities(List<TaskModel> tasks) {
    return tasks
        .where((task) => !task.isCompleted)
        .map((task) => task.priority)
        .toSet();
  }

  /// Get task statistics
  Future<TaskStatistics> getStatistics() async {
    if (_userId == null) {
      return TaskStatistics(
        totalTasks: 0,
        completedTasks: 0,
        pendingTasks: 0,
        completedThisWeek: 0,
        weeklyData: {},
        categoryData: {},
      );
    }

    try {
      final snapshot = await _tasksCollection.get();
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      int completedThisWeek = 0;
      final weeklyData = <int, int>{};
      final categoryData = <TaskCategory, int>{};

      for (int i = 0; i < 7; i++) {
        weeklyData[i] = 0;
      }

      for (final category in TaskCategory.values) {
        categoryData[category] = 0;
      }

      for (final task in tasks) {
        if (task.isCompleted && task.completedAt != null) {
          categoryData[task.category] = (categoryData[task.category] ?? 0) + 1;

          if (task.completedAt!.isAfter(weekStart)) {
            completedThisWeek++;
            final dayOfWeek = task.completedAt!.weekday - 1;
            weeklyData[dayOfWeek] = (weeklyData[dayOfWeek] ?? 0) + 1;
          }
        }
      }

      return TaskStatistics(
        totalTasks: tasks.length,
        completedTasks: tasks.where((t) => t.isCompleted).length,
        pendingTasks: tasks.where((t) => !t.isCompleted).length,
        completedThisWeek: completedThisWeek,
        weeklyData: weeklyData,
        categoryData: categoryData,
      );
    } catch (e) {
      return TaskStatistics(
        totalTasks: 0,
        completedTasks: 0,
        pendingTasks: 0,
        completedThisWeek: 0,
        weeklyData: {},
        categoryData: {},
      );
    }
  }
}

/// Result class for task operations
class TaskResult {
  final bool isSuccess;
  final TaskModel? task;
  final String? errorMessage;

  TaskResult._({
    required this.isSuccess,
    this.task,
    this.errorMessage,
  });

  factory TaskResult.success(TaskModel? task) {
    return TaskResult._(isSuccess: true, task: task);
  }

  factory TaskResult.failure(String message) {
    return TaskResult._(isSuccess: false, errorMessage: message);
  }
}

/// Task statistics model
class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int completedThisWeek;
  final Map<int, int> weeklyData; // day of week -> count
  final Map<TaskCategory, int> categoryData;

  TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.completedThisWeek,
    required this.weeklyData,
    required this.categoryData,
  });

  double get completionRate {
    if (totalTasks == 0) return 0;
    return completedTasks / totalTasks * 100;
  }

  int get mostProductiveDay {
    if (weeklyData.isEmpty) return 0;
    return weeklyData.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String get mostProductiveDayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[mostProductiveDay];
  }
}
