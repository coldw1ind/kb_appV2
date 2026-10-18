import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';

class WishesScreen extends StatefulWidget {
  const WishesScreen({super.key});

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _period;
  Map<String, String> _wishes = {};
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final userId = AuthState.id;
    if (userId == null) {
      setState(() {
        _error = 'Сначала войди';
        _loading = false;
      });
      return;
    }
    try {
      final periodRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/periods/current'));
      final period = (jsonDecode(periodRes.body) as Map)['period'];
      if (period == null) {
        setState(() {
          _period = null;
          _loading = false;
        });
        return;
      }
      final id = period['id'];
      final wishesRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/wishes?period_id=$id&user_id=$userId'),
      );
      final rows = ((jsonDecode(wishesRes.body)['wishes'] ?? []) as List);
      final mapped = <String, String>{};
      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        mapped[item['wish_date'].toString().substring(0, 10)] =
            item['wish_type'].toString();
      }
      final start = DateTime.parse(period['start_date'].toString());
      setState(() {
        _period = period.cast<String, dynamic>();
        _wishes = mapped;
        _focused = start;
        _selected = start;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Не удалось загрузить период';
        _loading = false;
      });
    }
  }

  Future<void> _setWish(DateTime day, String type) async {
    final period = _period;
    final userId = AuthState.id;
    if (period == null || userId == null) return;
    if (period['status'] != 'collecting') return;
    final key = _key(day);
    setState(() => _wishes[key] = type);
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/wishes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period_id': period['id'],
        'user_id': userId,
        'wish_date': key,
        'wish_type': type,
      }),
    );
    if (response.statusCode != 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не сохранилось')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    if (_period == null) {
      return const Scaffold(body: Center(child: Text('Набор пожеланий закрыт')));
    }

    final start = DateTime.parse(_period!['start_date'].toString());
    final end = DateTime.parse(_period!['end_date'].toString());
    final open = _period!['status'] == 'collecting';
    final selectedType = _wishes[_key(_selected)];

    return Scaffold(
      appBar: AppBar(title: Text(_period!['title'].toString())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(open ? 'Отметь дни' : 'Набор закрыт, правки смотрит менеджер'),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: start,
            lastDay: end,
            focusedDay: _focused,
            selectedDayPredicate: (day) => isSameDay(day, _selected),
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
            },
            eventLoader: (day) {
              final type = _wishes[_key(day)];
              return type == null ? [] : [type];
            },
          ),
          const SizedBox(height: 16),
          Text('Выбран ${_key(_selected)}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Хочу'),
                selected: selectedType == 'want',
                onSelected: open ? (_) => _setWish(_selected, 'want') : null,
              ),
              ChoiceChip(
                label: const Text('Могу'),
                selected: selectedType == 'can',
                onSelected: open ? (_) => _setWish(_selected, 'can') : null,
              ),
              ChoiceChip(
                label: const Text('Не могу'),
                selected: selectedType == 'off',
                onSelected: open ? (_) => _setWish(_selected, 'off') : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}