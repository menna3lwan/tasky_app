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
      return TaskResult.success(task.copyWith(id: docRef.id));
    } catch (e) {
      return TaskResult.failure('Failed to create task: ${e.toString()}');
    }
  }

  /// Get all tasks as stream (real-time updates) ordered by date
  Stream<List<TaskModel>> getTasksStream() {
    if (_userId == null) return Stream.value([]);

    return _tasksCollection
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
  }

  /// Get today's tasks
  Stream<List<TaskModel>> getTodayTasksStream() {
    if (_userId == null) return Stream.value([]);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _tasksCollection
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
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

      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _tasksCollection.doc(task.id).update({
        'isCompleted': updatedTask.isCompleted,
      });
      return TaskResult.success(updatedTask);
    } catch (e) {
      return TaskResult.failure('Failed to update task: ${e.toString()}');
    }
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
