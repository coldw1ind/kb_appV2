import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/app_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/auth_state.dart';


// ============================================
// ENUM ТИПОВ ДОСТИЖЕНИЙ
// ============================================
enum AchievementType {
  salesPercent,
  revenue,
  tips,
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _baseUrl = 'http://127.0.0.1:8000';

  final int _shiftStreak = 5;
  final List<_UserAchievement> _records = [];

  /// Актуальный id пользователя из глобального состояния.
  int? get _userId => AuthState.id;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ============================================
  // ПОДСЧЁТ СУММЫ ЗА СЕГОДНЯ
  // ============================================
  double _todaySum(AchievementType type) {
    final now = DateTime.now();
    return _records
        .where((r) =>
            r.type == type &&
            r.createdAt.year == now.year &&
            r.createdAt.month == now.month &&
            r.createdAt.day == now.day)
        .fold(0.0, (sum, r) => sum + r.value);
  }

  // ============================================
  // ПРЕОБРАЗОВАНИЕ API-СТРОКИ В ENUM
  // ============================================
  AchievementType? _typeFromApi(String raw) {
    for (final entry in _AchievementTypeMeta.values.entries) {
      if (entry.value.apiName == raw) return entry.key;
    }
    return null;
  }

  // ============================================
  // ЗАГРУЗКА ЗАПИСЕЙ С СЕРВЕРА
  // ============================================
  Future<void> _loadRecords() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/achievements?user_id=$userId'),
      );
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['achievements'] ?? []) as List<dynamic>;

      final items = <_UserAchievement>[];
      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        final type = _typeFromApi(item['type'].toString());
        if (type == null) continue;
        items.add(
          _UserAchievement(
            id: item['id'] as int,
            type: type,
            value: (item['value'] as num).toDouble(),
            createdAt: DateTime.parse(item['created_at'].toString()),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _records
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      print('ACHIEVEMENTS LOAD ERROR: $e');
    }
  }

  // ============================================
  // ДОБАВЛЕНИЕ ЗАПИСИ (с отправкой на сервер)
  // ============================================
  Future<void> _addRecord() async {
    final userId = _userId;
    if (userId == null) return;

    final record = await showModalBottomSheet<_UserAchievement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: const _AddAchievementSheet(),
        );
      },
    );

    if (record == null) return;

    try {
      final meta = _AchievementTypeMeta.values[record.type]!;
      final response = await http.post(
        Uri.parse('$_baseUrl/achievements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'type': meta.apiName,
          'value': record.value,
        }),
      );

      if (response.statusCode != 200) return;
      await _loadRecords();
    } catch (e) {
      print('ACHIEVEMENTS ADD ERROR: $e');
    }
  }

  // ============================================
  // УДАЛЕНИЕ ЗАПИСИ (с сервера)
  // ============================================
  Future<void> _removeRecord(int index) async {
    final record = _records[index];
    if (record.id != null) {
      try {
        await http.delete(
          Uri.parse('$_baseUrl/achievements/${record.id}'),
        );
      } catch (e) {
        print('ACHIEVEMENTS DELETE ERROR: $e');
      }
    }
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: [
                _StreakCard(streak: _shiftStreak),
                
                // ↓↓↓ ДОБАВЛЕННЫЙ БЛОК С КАРТОЧКАМИ ЗА СЕГОДНЯ ↓↓↓
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TodayCard(
                        title: 'Чаевые сегодня',
                        value: '${_todaySum(AchievementType.tips).toStringAsFixed(0)} ₽',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TodayCard(
                        title: 'Выручка сегодня',
                        value: '${_todaySum(AchievementType.revenue).toStringAsFixed(0)} ₽',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ↑↑↑ КОНЕЦ БЛОКА ↑↑↑

                Text('Мои записи', style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Процент с продаж, выручка и чаевые',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (_records.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                    radius: AppRadius.xl,
                    child: Column(
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 28,
                          color: AppColors.coral.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 10),
                        Text('Пока пусто', style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Добавь процент, выручку или чаевые после смены',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(_records.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecordCard(
                        record: _records[index],
                        onDelete: () => _removeRecord(index),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _addRecord,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Добавить достижение'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// МОДЕЛЬ ЗАПИСИ ДОСТИЖЕНИЯ
// ============================================
class _UserAchievement {
  final int? id;
  final AchievementType type;
  final double value;
  final DateTime createdAt;

  const _UserAchievement({
    this.id,
    required this.type,
    required this.value,
    required this.createdAt,
  });
}

// ============================================
// МЕТАДАННЫЕ ТИПОВ ДОСТИЖЕНИЙ
// ============================================
class _AchievementTypeMeta {
  final String apiName;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;

  const _AchievementTypeMeta({
    required this.apiName,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
  });

  static const values = <AchievementType, _AchievementTypeMeta>{
    AchievementType.salesPercent: _AchievementTypeMeta(
      apiName: 'sales_percent',
      label: 'Процент с продаж',
      unit: '%',
      icon: Icons.percent,
      color: AppColors.teal,
    ),
    AchievementType.revenue: _AchievementTypeMeta(
      apiName: 'revenue',
      label: 'Выручка',
      unit: '₽',
      icon: Icons.payments_outlined,
      color: AppColors.coral,
    ),
    AchievementType.tips: _AchievementTypeMeta(
      apiName: 'tips',
      label: 'Чаевые',
      unit: '₽',
      icon: Icons.volunteer_activism_outlined,
      color: AppColors.teal,
    ),
  };
}

// ============================================
// КАРТОЧКА СТРИКА
// ============================================
class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: AppRadius.xl,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.coral,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Стрик смен', style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Смены подряд без выходного',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streak',
                style: textTheme.headlineMedium?.copyWith(color: AppColors.coral),
              ),
              Text(
                _streakLabel(streak),
                style: textTheme.labelSmall?.copyWith(color: AppColors.coral),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _streakLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'смена подряд';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'смены подряд';
    }
    return 'смен подряд';
  }
}

// ============================================
// КАРТОЧКА ЗАПИСИ
// ============================================
class _RecordCard extends StatelessWidget {
  final _UserAchievement record;
  final VoidCallback onDelete;

  const _RecordCard({
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = _AchievementTypeMeta.values[record.type]!;
    final valueText = meta.unit == '%'
        ? '${_formatNumber(record.value)} %'
        : '${_formatNumber(record.value)} ₽';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(meta.icon, color: meta.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.label, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(_formatDate(record.createdAt), style: textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            valueText,
            style: textTheme.titleMedium?.copyWith(color: meta.color),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.iconMuted),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatDate(DateTime day) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${day.day} ${months[day.month]}';
  }
}

// ============================================
// BOTTOM SHEET ДЛЯ ДОБАВЛЕНИЯ
// ============================================
class _AddAchievementSheet extends StatefulWidget {
  const _AddAchievementSheet();

  @override
  State<_AddAchievementSheet> createState() => _AddAchievementSheetState();
}

class _AddAchievementSheetState extends State<_AddAchievementSheet> {
  final TextEditingController _valueController = TextEditingController();
  AchievementType _type = AchievementType.salesPercent;
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _valueController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);

    if (value == null || value <= 0) {
      setState(() => _error = 'Введи значение больше 0');
      return;
    }

    if (_type == AchievementType.salesPercent && value > 100) {
      setState(() => _error = 'Процент не может быть больше 100');
      return;
    }

    Navigator.pop(
      context,
      _UserAchievement(
        type: _type,
        value: value,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = _AchievementTypeMeta.values[_type]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Новое достижение', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<AchievementType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Тип'),
            items: AchievementType.values.map((type) {
              final item = _AchievementTypeMeta.values[type]!;
              return DropdownMenuItem(
                value: type,
                child: Text(item.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _type = value;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Значение',
              suffixText: meta.unit,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// КАРТОЧКА "СЕГОДНЯ" (добавлена в конец)
// ============================================
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            value, 
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}