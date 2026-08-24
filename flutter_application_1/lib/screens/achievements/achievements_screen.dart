import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/app_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const int _completedShifts = 12;

  static const List<_Achievement> _achievements = [
    _Achievement(
      title: 'Первая десятка',
      description: 'Отработай 10 смен — и ты уже не новичок в зале.',
      requiredShifts: 10,
      icon: Icons.local_bar_outlined,
    ),
    _Achievement(
      title: 'В ритме бара',
      description: '20 смен подряд в графике. Команда уже знает твоё имя.',
      requiredShifts: 20,
      icon: Icons.nightlife_outlined,
    ),
    _Achievement(
      title: 'Ветеран смены',
      description: '30 смен. На тебя можно оставить вечер без страховки.',
      requiredShifts: 30,
      icon: Icons.workspace_premium_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unlockedCount = _achievements
        .where((item) => _completedShifts >= item.requiredShifts)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            radius: AppRadius.xl,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.star, color: AppColors.coral, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Твои награды', style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '$unlockedCount из ${_achievements.length} открыто · $_completedShifts смен',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AchievementCard(
                achievement: achievement,
                completedShifts: _completedShifts,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String description;
  final int requiredShifts;
  final IconData icon;

  const _Achievement({
    required this.title,
    required this.description,
    required this.requiredShifts,
    required this.icon,
  });
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;
  final int completedShifts;

  const _AchievementCard({
    required this.achievement,
    required this.completedShifts,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unlocked = completedShifts >= achievement.requiredShifts;
    final progress = (completedShifts / achievement.requiredShifts).clamp(0.0, 1.0);
    final accent = unlocked ? AppColors.teal : AppColors.coral;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(achievement.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${achievement.requiredShifts} смен',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (unlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.teal),
                      const SizedBox(width: 4),
                      Text(
                        'Открыто',
                        style: textTheme.labelSmall?.copyWith(color: AppColors.teal),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: AppColors.coral),
                      const SizedBox(width: 4),
                      Text(
                        '$completedShifts / ${achievement.requiredShifts}',
                        style: textTheme.labelSmall?.copyWith(color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(achievement.description, style: textTheme.bodySmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
