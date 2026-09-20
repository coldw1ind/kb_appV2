import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    if (response.statusCode == 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отправлено управляющему')),
      );
      await _load();
    }
  }

  // ↓↓↓ ДОБАВЛЕНО ↓↓↓
  Future<void> _publish() async {
    final id = _period!['id'];
    final response = await http.post(
      Uri.parse('$_baseUrl/periods/$id/publish'),
    );
    if (response.statusCode == 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('График обновлён у всех')),
      );
      await _load();
    }
  }
  // ↑↑↑ конец добавления ↑↑↑

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final wish in _wishes) {
      final day = wish['wish_date'].toString();
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(wish);
    }
    final days = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Сборка графика')),
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
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            children: days.map((day) {
                              final items = grouped[day]!;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      day,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 8),
                                    ...items.map((wish) {
                                      final off = wish['wish_type'] == 'off';
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(wish['username'].toString()),
                                        subtitle: Text(_wishLabel(wish['wish_type'].toString())),
                                        trailing: off
                                            ? const Text('—')
                                            : TextButton(
                                                onPressed: () => _addDraft(wish),
                                                child: const Text('В смену'),
                                              ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // ↓↓↓ ЗАМЕНЕНО: две кнопки вместо одной ↓↓↓
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _drafts.isEmpty ? null : _sendToDirector,
                                  child: const Text('Отправить управляющему'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _drafts.isEmpty ? null : _publish,
                                  child: const Text('Утвердить график'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ↑↑↑ конец замены ↑↑↑
                      ],
                    ),
    );
  }
}