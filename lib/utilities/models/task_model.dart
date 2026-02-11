import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Task model representing a task in the app
class TaskModel {
  final String? id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final int priority; // 1-10 priority levels
  final bool isCompleted;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.priority = 1,
    this.isCompleted = false,
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

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    int? priority,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
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
    );
  }
}
