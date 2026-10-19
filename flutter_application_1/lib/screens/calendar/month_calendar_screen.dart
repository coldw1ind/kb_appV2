import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/screens/calendar/manager_schedule_screen.dart';
import 'package:flutter_application_1/screens/calendar/month_or_week.dart';
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
  Map<String, String> _wishes = {};
  bool _loading = true;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDate = DateTime(2024);
  final DateTime _lastDate = DateTime(2030);

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final shiftsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/shifts'));
      final peopleRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/employees'));
      final periodRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/periods/current'));

      final barById = <String, String>{};
      if (peopleRes.statusCode == 200) {
        final people = jsonDecode(peopleRes.body) as Map<String, dynamic>;
        for (final row in (people['employees'] ?? []) as List<dynamic>) {
          final item = row as Map<String, dynamic>;
          barById['${item['id']}'] = (item['bar'] ?? '').toString();
        }
      }

      final mapped = <DateTime, List<Map<String, String>>>{};
      if (shiftsRes.statusCode == 200) {
        final body = jsonDecode(shiftsRes.body) as Map<String, dynamic>;
        final myBar = AuthState.bar;
        final myId = '${AuthState.id}';
        for (final row in (body['shifts'] ?? []) as List<dynamic>) {
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
      }

      final wishes = <String, String>{};
      if (periodRes.statusCode == 200 && AuthState.id != null) {
        final period = (jsonDecode(periodRes.body) as Map)['period'];
        if (period != null) {
          final wishesRes = await http.get(Uri.parse(
            '${ApiConfig.baseUrl}/wishes?period_id=${period['id']}&user_id=${AuthState.id}',
          ));
          if (wishesRes.statusCode == 200) {
            final rows = (jsonDecode(wishesRes.body)['wishes'] ?? []) as List;
            for (final row in rows) {
              final item = row as Map<String, dynamic>;
              wishes[item['wish_date'].toString().substring(0, 10)] =
                  item['wish_type'].toString();
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _events = mapped;
        _wishes = wishes;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Future<void> _setWish(String type) async {
    final userId = AuthState.id;
    if (userId == null) return;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 60));
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (date.isBefore(start) || date.isAfter(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Можно отметить только ближайшие 60 дней')),
      );
      return;
    }

    final key = _key(_selectedDate);
    setState(() => _wishes[key] = type);

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/wishes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'wish_date': key,
        'wish_type': type,
        'period_id': 0,
      }),
    );
    if (!mounted) return;
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не сохранилось')),
      );
    }
  }

  String _wishLabel(String? type) {
    switch (type) {
      case 'can':
        return 'Могу';
      case 'off':
        return 'Не могу';
      default:
        return 'Не отмечено';
    }
  }

  // Цвет маркера для календаря
  Color? _wishColor(String? type) {
    switch (type) {
      case 'can':
        return Colors.green;
      case 'off':
        return Colors.redAccent;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDate);
    final textTheme = Theme.of(context).textTheme;
    final selectedWish = _wishes[_key(_selectedDate)];

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
              onRefresh: _load,
              child: ListView(
                children: [
                  TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: _firstDate,
                    lastDay: _lastDate,
                    selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                    eventLoader: (day) {
                      final wish = _wishes[_key(day)];
                      return wish == null ? _getEventsForDay(day) : [wish];
                    },
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDate = selected;
                        _focusedDay = focused;
                      });
                    },
                    headerStyle: const HeaderStyle(formatButtonVisible: false),
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
                    // ↓↓↓ ДОБАВЛЕНО: РАЗНЫЕ ЦВЕТА МАРКЕРОВ В ЗАВИСИМОСТИ ОТ ПОЖЕЛАНИЯ ↓↓↓
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final type = _wishes[_key(date)];
                        final color = _wishColor(type);
                        if (color == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    // ↑↑↑ КОНЕЦ БЛОКА ↑↑↑
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_key(_selectedDate)} · ${_wishLabel(selectedWish)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            // ↓↓↓ УБРАНА КНОПКА "ХОЧУ" ↓↓↓
                            ChoiceChip(
                              label: const Text('Могу'),
                              selected: selectedWish == 'can',
                              onSelected: (_) => _setWish('can'),
                            ),
                            ChoiceChip(
                              label: const Text('Не могу'),
                              selected: selectedWish == 'off',
                              onSelected: (_) => _setWish('off'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'В этот день утверждённых смен нет',
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
                          child: Text(
                            mine
                                ? '${event['time']}  ${event['role']} — ${event['name']} (вы)'
                                : '${event['time']}  ${event['role']} — ${event['name']}',
                          ),
                        ),
                      );
                    }),
                  if (AuthState.role == 'Менеджер' || AuthState.role == 'Управляющий')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: SizedBox(
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