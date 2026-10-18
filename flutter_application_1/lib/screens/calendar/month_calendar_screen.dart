import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/screens/calendar/manager_schedule_screen.dart';
import 'package:flutter_application_1/screens/calendar/month_or_week.dart';
import 'package:flutter_application_1/screens/calendar/wishes_screen.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/app_card.dart';

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
  bool _loading = true;

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
    setState(() => _loading = true);
    try {
      final shiftsRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/shifts'),
      );
      final peopleRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/employees'),
      );
      if (shiftsRes.statusCode != 200) return;

      final barById = <String, String>{};
      if (peopleRes.statusCode == 200) {
        final people = jsonDecode(peopleRes.body) as Map<String, dynamic>;
        for (final row in (people['employees'] ?? []) as List<dynamic>) {
          final item = row as Map<String, dynamic>;
          barById['${item['id']}'] = (item['bar'] ?? '').toString();
        }
      }

      final body = jsonDecode(shiftsRes.body) as Map<String, dynamic>;
      final rows = (body['shifts'] ?? []) as List<dynamic>;
      final mapped = <DateTime, List<Map<String, String>>>{};
      final myBar = AuthState.bar;
      final myId = '${AuthState.id}';

      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        final userId = '${item['user_id']}';
        if (myBar.isNotEmpty && barById[userId] != myBar) continue;

        final parsed = DateTime.parse(item['date'].toString());
        final key = DateTime.utc(parsed.year, parsed.month, parsed.day);
        mapped.putIfAbsent(key, () => []);
        mapped[key]!.add({
          'time': item['time'].toString(),
          'role': item['role'].toString(),
          'name': item['name'].toString(),
          'mine': userId == myId ? '1' : '0',
        });
      }

      if (!mounted) return;
      setState(() => _events = mapped);
    } catch (e) {
      debugPrint('SHIFTS ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDate);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('График')),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadShifts,
              child: ListView(
                children: [
                  TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: _firstDate,
                    lastDay: _lastDate,
                    selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDate = selected;
                        _focusedDay = focused;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      markerDecoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'В этот день в твоём баре смен нет',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...events.map((event) {
                      final mine = event['mine'] == '1';
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (mine ? AppColors.coral : AppColors.teal)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  event['role'] == 'Бармен'
                                      ? Icons.local_bar_outlined
                                      : Icons.restaurant_outlined,
                                  color: mine ? AppColors.coral : AppColors.teal,
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
                                      mine
                                          ? '${event['role']} — ${event['name']} (вы)'
                                          : '${event['role']} — ${event['name']}',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WishesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_outline, size: 20),
                            label: const Text('Моя смена'),
                          ),
                        ),
                        if (AuthState.role == 'Менеджер' ||
                            AuthState.role == 'Управляющий') ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManagerScheduleScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                              label: const Text('Сборка графика'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}