import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Task category enum with colors
enum TaskCategory {
  personal('Personal', Color(0xFF5F33E1)),
  work('Work', Color(0xFF2196F3)),
  study('Study', Color(0xFF4CAF50)),
  health('Health', Color(0xFFE91E63)),
  shopping('Shopping', Color(0xFFFF9800)),
  other('Other', Color(0xFF9E9E9E));

  final String label;
  final Color color;

  const TaskCategory(this.label, this.color);

  static TaskCategory fromString(String? value) {
    return TaskCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskCategory.personal,
    );
  }
}

/// Task recurrence enum
enum TaskRecurrence {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  final String label;

  const TaskRecurrence(this.label);

  static TaskRecurrence fromString(String? value) {
    return TaskRecurrence.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskRecurrence.none,
    );
  }
}

/// Task model representing a task in the app
class TaskModel {
  final String? id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final int priority; // 1-10 priority levels
  final bool isCompleted;
  final TaskCategory category;
  final TaskRecurrence recurrence;
  final DateTime? completedAt;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.priority = 1,
    this.isCompleted = false,
    this.category = TaskCategory.personal,
    this.recurrence = TaskRecurrence.none,
    this.completedAt,
  });

  /// Get priority color based on value (1-10)
  Color get priorityColor {
    if (priority <= 3) {
      return const Color(0xFF5F33E1); // Purple for low (1-3)
    } else if (priority <= 6) {
      return const Color(0xFFFFA726); // Orange for medium (4-6)
    } else if (priority <= 8) {
      return const Color(0xFFFF5722); // Deep orange for high (7-8)
    } else {
      return const Color(0xFFE53935); // Red for urgent (9-10)
    }
  }

  /// Check if task is today
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if task is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dateTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        dateTime.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    return dateTime.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Check if task is upcoming (future date, not today)
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return taskDate.isAfter(today);
  }

  /// Check if task is on specific date
  bool isOnDate(DateTime date) {
    return dateTime.year == date.year &&
        dateTime.month == date.month &&
        dateTime.day == date.day;
  }

  /// Get next occurrence date based on recurrence
  DateTime? getNextOccurrence() {
    if (recurrence == TaskRecurrence.none) return null;

    DateTime next;
    switch (recurrence) {
      case TaskRecurrence.daily:
        next = dateTime.add(const Duration(days: 1));
        break;
      case TaskRecurrence.weekly:
        next = dateTime.add(const Duration(days: 7));
        break;
      case TaskRecurrence.monthly:
        next = DateTime(
          dateTime.year,
          dateTime.month + 1,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
        );
        break;
      case TaskRecurrence.none:
        return null;
    }
    return next;
  }

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    int? priority,
    bool? isCompleted,
    TaskCategory? category,
    TaskRecurrence? recurrence,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'priority': priority,
      'isCompleted': isCompleted,
      'category': category.name,
      'recurrence': recurrence.name,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Create from Firestore document
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      priority: data['priority'] ?? 1,
      isCompleted: data['isCompleted'] ?? false,
      category: TaskCategory.fromString(data['category']),
      recurrence: TaskRecurrence.fromString(data['recurrence']),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
