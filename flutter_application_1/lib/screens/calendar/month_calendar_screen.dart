import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/screens/calendar/month_or_week.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/app_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  final VoidCallback onSwitchToWeek;

  const CalendarScreen({
    super.key,
    required this.onSwitchToWeek,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, List<Map<String, String>>> _events = {};

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDate = DateTime(2024);
  final DateTime _lastDate = DateTime(2030);
  
  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/shifts'),
      );
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['shifts'] ?? []) as List<dynamic>;

      final mapped = <DateTime, List<Map<String, String>>>{};

      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        final parsed = DateTime.parse(item['date'].toString());
        final key = DateTime.utc(parsed.year, parsed.month, parsed.day);

        mapped.putIfAbsent(key, () => []);
        mapped[key]!.add({
          'time': item['time'].toString(),
          'role': item['role'].toString(),
          'name': item['name'].toString(),
        });
      }

      setState(() => _events = mapped);
    } catch (e) {
      print('SHIFTS ERROR: $e');
    }
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  String _formatDate(DateTime day) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${day.day} ${months[day.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDate);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('График'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: CalendarChange(
              isMonthView: true,
              onViewChanged: (isMonth) {
                if (!isMonth) widget.onSwitchToWeek();
              },
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(bottom: 8),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: _firstDate,
              lastDay: _lastDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) => _getEventsForDay(day),
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.teal),
                rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.teal),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                ),
                weekendTextStyle: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerSize: 6,
                outsideDaysVisible: false,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                weekendStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(
                  'Смены на ${_formatDate(_selectedDate)}',
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'В этот день смен нет',
                      style: textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                event['role'] == 'Бармен'
                                    ? Icons.local_bar_outlined
                                    : Icons.restaurant_outlined,
                                color: AppColors.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event['time']!, style: textTheme.titleMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${event['role']} — ${event['name']}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.iconMuted),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_outline, size: 20),
                label: const Text('Моя смена'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}