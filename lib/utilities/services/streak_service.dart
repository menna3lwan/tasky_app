import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

/// Achievement badge model
class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final int requiredStreak;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredStreak,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  AchievementBadge copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return AchievementBadge(
      id: id,
      title: title,
      description: description,
      requiredStreak: requiredStreak,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// Streak data model
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletionDate;
  final List<AchievementBadge> badges;

  StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletionDate,
    this.badges = const [],
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletionDate,
    List<AchievementBadge>? badges,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      badges: badges ?? this.badges,
    );
  }
}

/// Service for tracking daily task completion streaks
class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastCompletionKey = 'last_completion_date';
  static const String _badgesKey = 'unlocked_badges';

  /// Default achievement badges
  final List<AchievementBadge> _defaultBadges = [
    AchievementBadge(
      id: 'beginner',
      title: 'Getting Started',
      description: 'Complete tasks for 3 days in a row',
      requiredStreak: 3,
      icon: 'star',
    ),
    AchievementBadge(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Complete tasks for 7 days in a row',
      requiredStreak: 7,
      icon: 'local_fire_department',
    ),
    AchievementBadge(
      id: 'consistent',
      title: 'Consistent',
      description: 'Complete tasks for 14 days in a row',
      requiredStreak: 14,
      icon: 'emoji_events',
    ),
    AchievementBadge(
      id: 'monthly_master',
      title: 'Monthly Master',
      description: 'Complete tasks for 30 days in a row',
      requiredStreak: 30,
      icon: 'military_tech',
    ),
    AchievementBadge(
      id: 'dedicated',
      title: 'Dedicated',
      description: 'Complete tasks for 60 days in a row',
      requiredStreak: 60,
      icon: 'workspace_premium',
    ),
    AchievementBadge(
      id: 'legendary',
      title: 'Legendary',
      description: 'Complete tasks for 100 days in a row',
      requiredStreak: 100,
      icon: 'diamond',
    ),
  ];

  /// Get current streak data
  Future<StreakData> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();

    final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    final longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    final lastCompletionStr = prefs.getString(_lastCompletionKey);
    final unlockedBadgeIds = prefs.getStringList(_badgesKey) ?? [];

    DateTime? lastCompletion;
    if (lastCompletionStr != null) {
      lastCompletion = DateTime.tryParse(lastCompletionStr);
    }

    // Check if streak should be reset (no completion yesterday)
    final adjustedStreak = _checkAndResetStreak(currentStreak, lastCompletion);
    if (adjustedStreak != currentStreak) {
      await prefs.setInt(_currentStreakKey, adjustedStreak);
    }

    final badges = _defaultBadges.map((badge) {
      return badge.copyWith(
        isUnlocked: unlockedBadgeIds.contains(badge.id),
      );
    }).toList();

    return StreakData(
      currentStreak: adjustedStreak,
      longestStreak: longestStreak,
      lastCompletionDate: lastCompletion,
      badges: badges,
    );
  }

  /// Check if streak should be reset
  int _checkAndResetStreak(int currentStreak, DateTime? lastCompletion) {
    if (lastCompletion == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      lastCompletion.year,
      lastCompletion.month,
      lastCompletion.day,
    );

    final difference = today.difference(lastDate).inDays;

    // If more than 1 day has passed without completion, reset streak
    if (difference > 1) {
      return 0;
    }

    return currentStreak;
  }

  /// Update streak when a task is completed
  Future<StreakData> onTaskCompleted(List<TaskModel> allTasks) async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if any task was completed today
    final completedToday = allTasks.any((task) {
      if (!task.isCompleted || task.completedAt == null) return false;
      final completedDate = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );
      return completedDate == today;
    });

    if (!completedToday) {
      return getStreakData();
    }

    final lastCompletionStr = prefs.getString(_lastCompletionKey);
    DateTime? lastCompletion;
    if (lastCompletionStr != null) {
      lastCompletion = DateTime.tryParse(lastCompletionStr);
    }

    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    int longestStreak = prefs.getInt(_longestStreakKey) ?? 0;

    // Check if this is a new day completion
    if (lastCompletion != null) {
      final lastDate = DateTime(
        lastCompletion.year,
        lastCompletion.month,
        lastCompletion.day,
      );

      if (lastDate == today) {
        // Already counted today
        return getStreakData();
      }

      final difference = today.difference(lastDate).inDays;
      if (difference == 1) {
        // Consecutive day - increment streak
        currentStreak++;
      } else if (difference > 1) {
        // Streak broken - reset to 1
        currentStreak = 1;
      }
    } else {
      // First completion ever
      currentStreak = 1;
    }

    // Update longest streak if needed
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      await prefs.setInt(_longestStreakKey, longestStreak);
    }

    // Save updates
    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setString(_lastCompletionKey, today.toIso8601String());

    // Check for new badge unlocks
    await _checkBadgeUnlocks(currentStreak);

    return getStreakData();
  }

  /// Check and unlock badges based on current streak
  Future<List<AchievementBadge>> _checkBadgeUnlocks(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedBadgeIds = prefs.getStringList(_badgesKey) ?? [];

    final newlyUnlocked = <AchievementBadge>[];

    for (final badge in _defaultBadges) {
      if (!unlockedBadgeIds.contains(badge.id) &&
          currentStreak >= badge.requiredStreak) {
        unlockedBadgeIds.add(badge.id);
        newlyUnlocked.add(badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await prefs.setStringList(_badgesKey, unlockedBadgeIds);
    }

    return newlyUnlocked;
  }

  /// Reset streak (for testing purposes)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, 0);
    await prefs.remove(_lastCompletionKey);
  }

  /// Clear all streak data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStreakKey);
    await prefs.remove(_longestStreakKey);
    await prefs.remove(_lastCompletionKey);
    await prefs.remove(_badgesKey);
  }
}
