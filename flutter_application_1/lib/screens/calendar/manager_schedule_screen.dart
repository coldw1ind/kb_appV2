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

  Future<void> _addDraft(Map<String, dynamic> wish) async {
    final times = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _TimeDialog(),
    );
    if (times == null) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/draft-shifts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period_id': _period!['id'],
        'user_id': wish['user_id'],
        'shift_date': wish['wish_date'],
        'start_time': times['start'],
        'end_time': times['end'],
        'role': wish['employee_role'] ?? 'Официант',
      }),
    );
    if (response.statusCode == 200) await _load();
  }

  Future<void> _removeDraft(int id) async {
    await http.delete(Uri.parse('$_baseUrl/draft-shifts/$id'));
    await _load();
  }

  Future<void> _removeWish(int id) async {
    await http.delete(Uri.parse('$_baseUrl/wishes/$id'));
    await _load();
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
    final parsed = DateTime.parse(dayStr);
    const months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final title = '${weekdays[parsed.weekday - 1]}, ${parsed.day} ${months[parsed.month - 1]}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title),
          content: SizedBox(
            width: 320,
            child: items.isEmpty
                ? const Text('Никто не отметился')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((wish) {
                      final type = wish['wish_type'].toString();
                      final color = type == 'want'
                          ? Colors.orange
                          : type == 'can'
                              ? Colors.green
                              : type == 'off'
                                  ? Colors.redAccent
                                  : Colors.grey;
                      final label = type == 'want'
                          ? 'Хочет'
                          : type == 'can'
                              ? 'Может'
                              : type == 'off'
                                  ? 'Не может'
                                  : 'Нет';
                      
                      // Ищем существующий черновик для этого пользователя на этот день
                      final draft = _drafts.firstWhere(
                        (d) => d['user_id'] == wish['user_id'] && d['shift_date'].toString().startsWith(dayStr),
                        orElse: () => <String, dynamic>{},
                      );
                      final hasDraft = draft.isNotEmpty; // Проверяем, есть ли данные

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(wish['username'].toString()),
                        subtitle: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(label, style: TextStyle(color: color, fontSize: 13)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ↓↓↓ ИСПОЛЬЗУЕМ hasDraft ВМЕСТО draft != null ↓↓↓
                            if (hasDraft) ...[
                              Text(
                                draft['time'].toString(),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _removeDraft(draft['id'] as int);
                                },
                                child: const Text('Убрать'),
                              ),
                            ] else if (type != 'off') ...[
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _addDraft(wish);
                                },
                                child: const Text('В смену'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _removeWish(wish['id'] as int);
                                },
                                child: const Text('Снять'),
                              ),
                            ] else ...[
                              const Text('—'),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }

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
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: leading + monthDays.length,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day = monthDays[index - leading];
                final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final count = counts[key] ?? 0;
                return InkWell(
                  onTap: () => _openDay(key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekdays[day.weekday],
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7A716A)),
                        ),
                        const Spacer(),
                        Text(
                          '${day.day}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          count == 0 ? 'пусто' : '$count чел.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7A716A)),
                        ),
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
                        Expanded(
                          child: days.isEmpty
                              ? const Center(child: Text('Пожеланий пока нет'))
                              : _monthGrid(days, counts),
                        ),
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

// ↓↓↓ ДИАЛОГ ДЛЯ ВВОДА ВРЕМЕНИ ↓↓↓
class _TimeDialog extends StatefulWidget {
  const _TimeDialog();

  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  final _start = TextEditingController(text: '10:00');
  final _end = TextEditingController(text: '18:00');

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Время смены'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _start, decoration: const InputDecoration(labelText: 'Начало')),
          const SizedBox(height: 12),
          TextField(controller: _end, decoration: const InputDecoration(labelText: 'Конец')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'start': _start.text.trim(),
            'end': _end.text.trim(),
          }),
          child: const Text('Поставить'),
        ),
      ],
    );
  }
}
// ↑↑↑ КОНЕЦ ДИАЛОГА ↑↑↑