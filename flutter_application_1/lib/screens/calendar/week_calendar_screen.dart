import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/calendar/month_or_week.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/app_card.dart';
import 'package:http/http.dart' as http;  // ✅ Добавлено
import 'dart:convert';                    // ✅ Добавлено

class WeekCalendarScreen extends StatefulWidget {
  final VoidCallback onSwitchToMonth;

  const WeekCalendarScreen({
    super.key,
    required this.onSwitchToMonth,
  });

  @override
  State<WeekCalendarScreen> createState() => _WeekCalendarScreenState();
}

class _WeekCalendarScreenState extends State<WeekCalendarScreen> {
  late DateTime _weekStart;
  
  // ✅ Переименовал в _shifts для единообразия
  Map<DateTime, Map<String, String>?> _shifts = {};

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _loadShifts();  // ✅ Вызываем загрузку данных
  }

  // ✅ Исправленный метод _loadShifts
  Future<void> _loadShifts() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/shifts')
      );
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['shifts'] ?? []) as List<dynamic>;

      final mapped = <DateTime, Map<String, String>>{};  // Временный Map

      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        final parsed = DateTime.parse(item['date'].toString());
        final key = DateTime(parsed.year, parsed.month, parsed.day);
        // Для недельного режима храним только одну смену на день
        mapped[key] = {
          'time': item['time'].toString(),
          'role': item['role'].toString(),
          'name': item['name'].toString(),
        };
      }

      setState(() => _shifts = mapped);
    } catch (e) {
      print('SHIFTS ERROR: $e');  // ✅ Добавлена ;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * offset));
      // ✅ Не нужно перегенерировать демо-данные, они уже загружены
    });
  }

  String _formatWeekRange() {
    final end = _weekStart.add(const Duration(days: 6));
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];

    if (_weekStart.month == end.month) {
      return '${_weekStart.day} – ${end.day} ${months[_weekStart.month]} ${end.year}';
    }
    return '${_weekStart.day} ${months[_weekStart.month]} – ${end.day} ${months[end.month]} ${end.year}';
  }

  String _dayName(int weekday) {
    const names = [
      '', 'Понедельник', 'Вторник', 'Среда', 'Четверг',
      'Пятница', 'Суббота', 'Воскресенье'
    ];
    return names[weekday];
  }

  String _formatDay(DateTime date) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Мои смены', style: textTheme.headlineMedium),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CalendarChange(
                isMonthView: false,
                onViewChanged: (isMonth) {
                  if (isMonth) widget.onSwitchToMonth();
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeWeek(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.coral),
                      const SizedBox(width: 8),
                      Text(_formatWeekRange(), style: textTheme.titleMedium),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _changeWeek(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final shift = _shifts[_dateOnly(day)];  // ✅ _shifts объявлен
                  final isShift = shift != null;

                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    radius: AppRadius.xl,
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isShift ? AppColors.coral : AppColors.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_dayName(day.weekday), style: textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(_formatDay(day), style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (isShift) ...[
                          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.coral),
                          const SizedBox(width: 6),
                          Text(shift['time']!, style: textTheme.titleSmall),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.coral.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, size: 14, color: AppColors.coral),
                                const SizedBox(width: 4),
                                Text(
                                  'Смена',
                                  style: textTheme.labelSmall?.copyWith(color: AppColors.coral),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.beach_access_rounded, size: 18, color: AppColors.textHint),
                          const SizedBox(width: 6),
                          Text(
                            'Выходной',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}