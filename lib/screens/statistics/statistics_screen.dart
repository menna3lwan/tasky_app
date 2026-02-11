import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/services/streak_service.dart';
import '../../utilities/services/task_service.dart';

/// Statistics and productivity screen
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _taskService = TaskService();
  final _streakService = StreakService();

  TaskStatistics? _statistics;
  StreakData? _streakData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final statistics = await _taskService.getStatistics();
    final streakData = await _streakService.getStreakData();

    if (mounted) {
      setState(() {
        _statistics = statistics;
        _streakData = streakData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Statistics',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: responsive.fontSize(mobile: 18, tablet: 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(responsive.spacing(mobile: 20, tablet: 24)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview cards
                        _buildOverviewCards(responsive),
                        SizedBox(height: responsive.spacing(mobile: 24, tablet: 32)),

                        // Weekly productivity chart
                        _buildSectionTitle('Weekly Productivity', responsive),
                        SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
                        _buildWeeklyChart(responsive),
                        SizedBox(height: responsive.spacing(mobile: 24, tablet: 32)),

                        // Category breakdown
                        _buildSectionTitle('Tasks by Category', responsive),
                        SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
                        _buildCategoryChart(responsive),
                        SizedBox(height: responsive.spacing(mobile: 24, tablet: 32)),

                        // Achievements
                        _buildSectionTitle('Achievements', responsive),
                        SizedBox(height: responsive.spacing(mobile: 16, tablet: 20)),
                        _buildAchievements(responsive),
                        SizedBox(height: responsive.spacing(mobile: 40, tablet: 60)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, ResponsiveHelper responsive) {
    return Text(
      title,
      style: TextStyle(
        fontSize: responsive.fontSize(mobile: 18, tablet: 20),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOverviewCards(ResponsiveHelper responsive) {
    final stats = _statistics;
    final streak = _streakData;

    return GridView.count(
      crossAxisCount: responsive.responsive<int>(mobile: 2, tablet: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: responsive.spacing(mobile: 12, tablet: 16),
      mainAxisSpacing: responsive.spacing(mobile: 12, tablet: 16),
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: 'Total Tasks',
          value: '${stats?.totalTasks ?? 0}',
          icon: Icons.task_alt,
          color: AppColors.primary,
          responsive: responsive,
        ),
        _buildStatCard(
          title: 'Completed',
          value: '${stats?.completedTasks ?? 0}',
          icon: Icons.check_circle,
          color: const Color(0xFF4CAF50),
          responsive: responsive,
        ),
        _buildStatCard(
          title: 'Current Streak',
          value: '${streak?.currentStreak ?? 0}',
          icon: Icons.local_fire_department,
          color: const Color(0xFFFF9800),
          responsive: responsive,
        ),
        _buildStatCard(
          title: 'Best Streak',
          value: '${streak?.longestStreak ?? 0}',
          icon: Icons.emoji_events,
          color: const Color(0xFFE91E63),
          responsive: responsive,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ResponsiveHelper responsive,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(mobile: 16, tablet: 20)),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: responsive.spacing(mobile: 28, tablet: 32)),
          SizedBox(height: responsive.spacing(mobile: 8, tablet: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(mobile: 24, tablet: 28),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: responsive.spacing(mobile: 4, tablet: 6)),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(mobile: 12, tablet: 14),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(ResponsiveHelper responsive) {
    final weeklyData = _statistics?.weeklyData ?? {};
    final maxValue = weeklyData.values.isEmpty
        ? 5.0
        : (weeklyData.values.reduce((a, b) => a > b ? a : b) + 1).toDouble();

    return Container(
      height: responsive.responsive<double>(mobile: 200, tablet: 250),
      padding: EdgeInsets.all(responsive.spacing(mobile: 16, tablet: 20)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final index = value.toInt();
                  if (index >= 0 && index < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[index],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: responsive.fontSize(mobile: 12, tablet: 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: responsive.fontSize(mobile: 10, tablet: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFFE0E0E0),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: List.generate(7, (index) {
            final value = weeklyData[index]?.toDouble() ?? 0;
            final isMostProductive = _statistics?.mostProductiveDay == index && value > 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: isMostProductive ? const Color(0xFFFF9800) : AppColors.primary,
                  width: responsive.responsive<double>(mobile: 20, tablet: 24),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryChart(ResponsiveHelper responsive) {
    final categoryData = _statistics?.categoryData ?? {};
    final total = categoryData.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        padding: EdgeInsets.all(responsive.spacing(mobile: 24, tablet: 32)),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No completed tasks yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: responsive.fontSize(mobile: 14, tablet: 16),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(responsive.spacing(mobile: 16, tablet: 20)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Pie chart
          SizedBox(
            height: responsive.responsive<double>(mobile: 150, tablet: 180),
            width: responsive.responsive<double>(mobile: 150, tablet: 180),
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: responsive.responsive<double>(mobile: 30, tablet: 40),
                sections: categoryData.entries
                    .where((e) => e.value > 0)
                    .map((entry) {
                  final percentage = (entry.value / total * 100);
                  return PieChartSectionData(
                    color: entry.key.color,
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: responsive.responsive<double>(mobile: 40, tablet: 50),
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontSize: responsive.fontSize(mobile: 10, tablet: 12),
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(width: responsive.spacing(mobile: 16, tablet: 24)),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryData.entries
                  .where((e) => e.value > 0)
                  .map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: responsive.spacing(mobile: 8, tablet: 12)),
                  child: Row(
                    children: [
                      Container(
                        width: responsive.spacing(mobile: 12, tablet: 14),
                        height: responsive.spacing(mobile: 12, tablet: 14),
                        decoration: BoxDecoration(
                          color: entry.key.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(mobile: 8, tablet: 10)),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: TextStyle(
                            fontSize: responsive.fontSize(mobile: 13, tablet: 14),
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(mobile: 13, tablet: 14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(ResponsiveHelper responsive) {
    final badges = _streakData?.badges ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.responsive<int>(mobile: 3, tablet: 4, desktop: 6),
        crossAxisSpacing: responsive.spacing(mobile: 12, tablet: 16),
        mainAxisSpacing: responsive.spacing(mobile: 12, tablet: 16),
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeItem(badge, responsive);
      },
    );
  }

  Widget _buildBadgeItem(AchievementBadge badge, ResponsiveHelper responsive) {
    final isUnlocked = badge.isUnlocked;

    IconData getIcon() {
      switch (badge.icon) {
        case 'star':
          return Icons.star;
        case 'local_fire_department':
          return Icons.local_fire_department;
        case 'emoji_events':
          return Icons.emoji_events;
        case 'military_tech':
          return Icons.military_tech;
        case 'workspace_premium':
          return Icons.workspace_premium;
        case 'diamond':
          return Icons.diamond;
        default:
          return Icons.star;
      }
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(getIcon(), color: isUnlocked ? AppColors.primary : AppColors.textHint),
                SizedBox(width: responsive.spacing(mobile: 8)),
                Expanded(child: Text(badge.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.description),
                SizedBox(height: responsive.spacing(mobile: 8)),
                Text(
                  isUnlocked ? 'Unlocked!' : '${badge.requiredStreak} day streak required',
                  style: TextStyle(
                    color: isUnlocked ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(mobile: 12, tablet: 16)),
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.primary.withAlpha(25) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? AppColors.primary.withAlpha(76) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getIcon(),
              size: responsive.spacing(mobile: 32, tablet: 40),
              color: isUnlocked ? AppColors.primary : AppColors.textHint,
            ),
            SizedBox(height: responsive.spacing(mobile: 8, tablet: 10)),
            Text(
              badge.title,
              style: TextStyle(
                fontSize: responsive.fontSize(mobile: 11, tablet: 12),
                fontWeight: FontWeight.w500,
                color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
