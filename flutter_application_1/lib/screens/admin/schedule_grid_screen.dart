import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScheduleGridScreen extends StatefulWidget {
  const ScheduleGridScreen({super.key});

  @override
  State<ScheduleGridScreen> createState() => _ScheduleGridScreenState();
}

class _ScheduleGridScreenState extends State<ScheduleGridScreen> {
  static const _baseUrl = 'http://127.0.0.1:8000';

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _period;
  List<Map<String, dynamic>> _wishes = [];
  List<Map<String, dynamic>> _drafts = [];

  // --- Поля для создания периода ---
  final _title = TextEditingController(text: 'График на неделю');
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 6));

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Вынесенная функция форматирования даты
  String _formatDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

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

      final id = period['id'];
      final wishesRes = await http.get(Uri.parse('$_baseUrl/wishes?period_id=$id'));
      final draftsRes = await http.get(Uri.parse('$_baseUrl/draft-shifts?period_id=$id'));

      setState(() {
        _period = period;
        _wishes = ((jsonDecode(wishesRes.body)['wishes'] ?? []) as List)
            .cast<Map<String, dynamic>>();
        _drafts = ((jsonDecode(draftsRes.body)['draft_shifts'] ?? []) as List)
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить сетку';
        _loading = false;
      });
    }
  }

  // --- Метод создания периода ---
  Future<void> _createPeriod() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/periods'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': _title.text.trim(),
        'start_date': _formatDate(_start),
        'end_date': _formatDate(_end),
      }),
    );
    if (response.statusCode == 200) {
      await _load();
    }
  }

  List<DateTime> _days() {
    final start = DateTime.parse(_period!['start_date'].toString());
    final end = DateTime.parse(_period!['end_date'].toString());
    return [
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1)))
        DateTime(d.year, d.month, d.day),
    ];
  }

  List<Map<String, dynamic>> _people() {
    final map = <int, String>{};
    for (final wish in _wishes) {
      map[wish['user_id'] as int] = wish['username'].toString();
    }
    final list = map.entries
        .map((e) => {'user_id': e.key, 'username': e.value})
        .toList()
      ..sort((a, b) => a['username'].toString().compareTo(b['username'].toString()));
    return list;
  }

  String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Map<String, dynamic>? _wishFor(int userId, String date) {
    for (final wish in _wishes) {
      if (wish['user_id'] == userId && wish['wish_date'].toString() == date) {
        return wish;
      }
    }
    return null;
  }

  Map<String, dynamic>? _draftFor(int userId, String date) {
    for (final draft in _drafts) {
      if (draft['user_id'] == userId && draft['shift_date'].toString() == date) {
        return draft;
      }
    }
    return null;
  }

  Color _cellColor(Map<String, dynamic>? wish, Map<String, dynamic>? draft) {
    if (draft != null) return const Color(0xFFD1FAE5);
    switch (wish?['wish_type']) {
      case 'want':
        return const Color(0xFFFFE4D6);
      case 'can':
        return const Color(0xFFE0F2FE);
      case 'off':
        return const Color(0xFFF3F4F6);
      default:
        return Colors.white;
    }
  }

  String _cellText(Map<String, dynamic>? wish, Map<String, dynamic>? draft) {
    if (draft != null) return draft['time'].toString();
    switch (wish?['wish_type']) {
      case 'want':
        return 'Хочет';
      case 'can':
        return 'Может';
      case 'off':
        return 'Выходной';
      default:
        return '—';
    }
  }

  Future<void> _editCell(int userId, String username, String date) async {
    final wish = _wishFor(userId, date);
    if (wish?['wish_type'] == 'off') return;

    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '18:00');
    String role = 'Официант';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$username\n$date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Начало'),
              ),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'Конец'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'Официант', child: Text('Официант')),
                  DropdownMenuItem(value: 'Бармен', child: Text('Бармен')),
                ],
                onChanged: (value) {
                  if (value != null) role = value;
                },
                decoration: const InputDecoration(labelText: 'Роль'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Поставить'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/draft-shifts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period_id': _period!['id'],
        'user_id': userId,
        'shift_date': date,
        'start_time': startController.text.trim(),
        'end_time': endController.text.trim(),
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _period == null
                  // ↓↓↓ НОВАЯ ФОРМА СОЗДАНИЯ ПЕРИОДА ↓↓↓
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Нет открытого периода',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _title,
                            decoration: const InputDecoration(labelText: 'Название'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Text('С ${_formatDate(_start)}')),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                    initialDate: _start,
                                  );
                                  if (picked != null) setState(() => _start = picked);
                                },
                                child: const Text('Начало'),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('По ${_formatDate(_end)}')),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                    initialDate: _end,
                                  );
                                  if (picked != null) setState(() => _end = picked);
                                },
                                child: const Text('Конец'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _createPeriod,
                            child: const Text('Открыть набор'),
                          ),
                        ],
                      ),
                    )
                  // ↑↑↑ КОНЕЦ ФОРМЫ ↑↑↑
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _period!['title'].toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('Статус: ${_period!['status']}'),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: _buildTable(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ↓↓↓ БЛОК КНОПОК С ПРОВЕРКОЙ СТАТУСА ↓↓↓
                          Row(
                            children: [
                              if (_period!['status'] == 'collecting')
                                ElevatedButton(
                                  onPressed: () async {
                                    await http.post(Uri.parse(
                                        '$_baseUrl/periods/${_period!['id']}/close-wishes'));
                                    await _load();
                                  },
                                  child: const Text('Закрыть набор'),
                                ),
                              if (_period!['status'] == 'manager_review')
                                ElevatedButton(
                                  onPressed: () async {
                                    await http.post(Uri.parse(
                                        '$_baseUrl/periods/${_period!['id']}/send-to-director'));
                                    await _load();
                                  },
                                  child: const Text('Отправить управляющему'),
                                ),
                              if (_period!['status'] == 'director_review')
                                ElevatedButton(
                                  onPressed: () async {
                                    await http.post(Uri.parse(
                                        '$_baseUrl/periods/${_period!['id']}/publish'));
                                    await _load();
                                  },
                                  child: const Text('Утвердить график'),
                                ),
                            ],
                          ),
                          // ↑↑↑ КОНЕЦ БЛОКА ↑↑↑
                        ],
                      ),
                    ),
    );
  }

  Widget _buildTable() {
    final days = _days();
    final people = _people();

    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFFFFE4D6)),
      columns: [
        const DataColumn(label: Text('Сотрудник')),
        ...days.map(
          (day) => DataColumn(label: Text('${day.day}.${day.month}')),
        ),
      ],
      rows: people.map((person) {
        final userId = person['user_id'] as int;
        return DataRow(
          cells: [
            DataCell(Text(person['username'].toString())),
            ...days.map((day) {
              final date = _dateKey(day);
              final wish = _wishFor(userId, date);
              final draft = _draftFor(userId, date);
              return DataCell(
                InkWell(
                  onTap: () {
                    final status = _period?['status'];
                    if (status != 'manager_review' && status != 'director_review') {
                      return;
                    }
                    
                    _editCell(
                      userId,
                      person['username'].toString(),
                      date,
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    color: _cellColor(wish, draft),
                    padding: const EdgeInsets.all(8),
                    child: Text(_cellText(wish, draft)),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}