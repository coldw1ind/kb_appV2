import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/screens/reglog_panel/login_screen.dart';

class ManagerScheduleScreen extends StatefulWidget {
  const ManagerScheduleScreen({super.key});

  @override
  State<ManagerScheduleScreen> createState() => _ManagerScheduleScreenState();
}

class _ManagerScheduleScreenState extends State<ManagerScheduleScreen> {
  static const _baseUrl = 'http://127.0.0.1:8000';

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _period;
  List<Map<String, dynamic>> _wishes = [];
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final periodRes = await http.get(Uri.parse('$_baseUrl/periods/current'));
      final periodBody = jsonDecode(periodRes.body) as Map<String, dynamic>;
      final period = periodBody['period'] as Map<String, dynamic>?;

      if (period == null) {
        setState(() {
          _period = null;
          _loading = false;
        });
        return;
      }

      final periodId = period['id'];

      final wishesRes = await http.get(
        Uri.parse('$_baseUrl/wishes?period_id=$periodId'),
      );
      final draftsRes = await http.get(
        Uri.parse('$_baseUrl/draft-shifts?period_id=$periodId'),
      );

      final wishesBody = jsonDecode(wishesRes.body) as Map<String, dynamic>;
      final draftsBody = jsonDecode(draftsRes.body) as Map<String, dynamic>;

      setState(() {
        _period = period;
        _wishes = ((wishesBody['wishes'] ?? []) as List).cast<Map<String, dynamic>>();
        _drafts = ((draftsBody['draft_shifts'] ?? []) as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить сводку';
        _loading = false;
      });
    }
  }

  String _wishLabel(String type) {
    switch (type) {
      case 'want':
        return 'Хочет';
      case 'can':
        return 'Может';
      case 'off':
        return 'Не может';
      default:
        return type;
    }
  }

  Future<void> _addDraft(Map<String, dynamic> wish) async {
    if (wish['wish_type'] == 'off') return;

    final response = await http.post(
      Uri.parse('$_baseUrl/draft-shifts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period_id': _period!['id'],
        'user_id': wish['user_id'],
        'shift_date': wish['wish_date'],
        'start_time': '10:00',
        'end_time': '18:00',
        'role': 'Официант',
      }),
    );

    if (response.statusCode == 200) {
      await _load();
    }
  }

  Future<void> _sendToDirector() async {
    final id = _period!['id'];
    final response = await http.post(
      Uri.parse('$_baseUrl/periods/$id/send-to-director'),
    );
    
    if (!mounted) return;
    final ok = response.statusCode == 200;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Отправлено управляющему' : response.body)),
    );
    if (ok) await _load();
  }

  Future<void> _publish() async {
    final id = _period!['id'];
    final response = await http.post(
      Uri.parse('$_baseUrl/periods/$id/publish'),
    );
    if (!mounted) return;
    final ok = response.statusCode == 200;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'График обновлён у всех' : response.body)),
    );
    if (ok) await _load();
  }

  void _openDay(String dayStr) {
    final items = _wishes.where((w) => w['wish_date'].toString() == dayStr).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                dayStr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('Никто не отметился'),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: items.map((wish) {
                      final off = wish['wish_type'] == 'off';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(wish['username'].toString()),
                        subtitle: Text(_wishLabel(wish['wish_type'].toString())),
                        trailing: off
                            ? const Text('—')
                            : TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _addDraft(wish);
                                },
                                child: const Text('В смену'),
                              ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ↓↓↓ ДОБАВЛЕН МЕТОД ДЛЯ ОТРИСОВКИ СЕТКИ ПО МЕСЯЦАМ ↓↓↓
  Widget _monthGrid(List<String> days, Map<String, int> counts) {
    const weekdays = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    const months = ['', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];

    final parsed = days.map(DateTime.parse).toList()..sort();
    final byMonth = <String, List<DateTime>>{};
    for (final day in parsed) {
      byMonth.putIfAbsent('${day.year}-${day.month}', () => []).add(day);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: byMonth.entries.map((entry) {
        final monthDays = entry.value;
        final first = monthDays.first;
        final leading = first.weekday - 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text('${months[first.month]} ${first.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.75,
              ),
              itemCount: leading + monthDays.length,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day = monthDays[index - leading];
                final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final count = counts[key] ?? 0;
                return InkWell(
                  onTap: () => _openDay(key),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekdays[day.weekday], style: const TextStyle(fontSize: 10, color: Color(0xFF7A716A))),
                        const Spacer(),
                        Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(count == 0 ? '—' : '$count', style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }
  // ↑↑↑ КОНЕЦ ДОБАВЛЕННОГО МЕТОДА ↑↑↑

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final wish in _wishes) {
      final day = wish['wish_date'].toString();
      counts[day] = (counts[day] ?? 0) + 1;
    }
    
    final days = counts.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сборка графика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthState.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _period == null
                  ? const Center(child: Text('Нет открытого периода'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _period!['title'].toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text('Статус: ${_period!['status']}'),
                              Text('Черновик смен: ${_drafts.length}'),
                            ],
                          ),
                        ),
                        // ↓↓↓ ЗАМЕНЕНО: ВЫЗОВ _monthGrid ВМЕСТО СТАРОГО GRIDVIEW ↓↓↓
                        Expanded(
                          child: days.isEmpty
                              ? const Center(child: Text('Пожеланий пока нет'))
                              : _monthGrid(days, counts),
                        ),
                        // ↑↑↑ КОНЕЦ ЗАМЕНЫ ↑↑↑
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            children: [
                              if (AuthState.role == 'Менеджер' && _period?['status'] != 'director_review')
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _wishes.isEmpty ? null : _sendToDirector,
                                    child: const Text('Отправить на согласование'),
                                  ),
                                ),
                              if (AuthState.role == 'Управляющий' &&
                                  _period?['status'] == 'director_review')
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _publish,
                                    child: const Text('Подтвердить график'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}