import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/screens/calendar/month_or_week.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/widgets/app_card.dart';

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
  Map<DateTime, List<Map<String, String>>> _shifts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _weekStart = _monday(DateTime.now());
    _load();
  }

  DateTime _monday(DateTime date) =>
      DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));

  DateTime _key(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final shiftsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/shifts'));
      final peopleRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/employees'));
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
      final mapped = <DateTime, List<Map<String, String>>>{};
      final myBar = AuthState.bar;
      final myId = '${AuthState.id}';

      for (final row in (body['shifts'] ?? []) as List<dynamic>) {
        final item = row as Map<String, dynamic>;
        final userId = '${item['user_id']}';
        if (myBar.isNotEmpty && barById[userId] != myBar) continue;
        final parsed = DateTime.parse(item['date'].toString());
        final key = _key(parsed);
        mapped.putIfAbsent(key, () => []);
        mapped[key]!.add({
          'time': item['time'].toString(),
          'role': item['role'].toString(),
          'name': item['name'].toString(),
          'mine': userId == myId ? '1' : '0',
        });
      }

      if (!mounted) return;
      setState(() => _shifts = mapped);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _range() {
    final end = _weekStart.add(const Duration(days: 6));
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    if (_weekStart.month == end.month) {
      return '${_weekStart.day} – ${end.day} ${months[_weekStart.month]}';
    }
    return '${_weekStart.day} ${months[_weekStart.month]} – ${end.day} ${months[end.month]}';
  }

  @override
  Widget build(BuildContext context) {
    const names = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Scaffold(
      appBar: AppBar(title: const Text('График')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: CalendarChange(
              isMonthView: false,
              onViewChanged: (isMonth) {
                if (isMonth) widget.onSwitchToMonth();
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: Text(_range(), textAlign: TextAlign.center)),
              IconButton(
                onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = _weekStart.add(Duration(days: index));
                      final events = _shifts[_key(day)] ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${names[day.weekday]}  ${day.day}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              if (events.isEmpty)
                                const Text('Выходной', style: TextStyle(color: AppColors.textHint))
                              else
                                ...events.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        e['mine'] == '1'
                                            ? '${e['time']}  ${e['role']} — ${e['name']} (вы)'
                                            : '${e['time']}  ${e['role']} — ${e['name']}',
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}