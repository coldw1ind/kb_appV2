import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WishesScreen extends StatefulWidget {
  const WishesScreen({super.key});

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> {
  static const _baseUrl = 'http://127.0.0.1:8000';
  static const _userId = 1; // потом подставишь id после логина

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _period;
  final Map<String, String> _wishes = {};

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
      if (periodRes.statusCode != 200) {
        throw Exception('period ${periodRes.statusCode}');
      }

      final periodBody = jsonDecode(periodRes.body) as Map<String, dynamic>;
      final period = periodBody['period'] as Map<String, dynamic>?;
      if (period == null) {
        setState(() {
          _period = null;
          _loading = false;
        });
        return;
      }

      final wishesRes = await http.get(
        Uri.parse(
          '$_baseUrl/wishes?period_id=${period['id']}&user_id=$_userId',
        ),
      );
      if (wishesRes.statusCode != 200) {
        throw Exception('wishes ${wishesRes.statusCode}');
      }

      final wishesBody = jsonDecode(wishesRes.body) as Map<String, dynamic>;
      final rows = (wishesBody['wishes'] ?? []) as List<dynamic>;

      _wishes.clear();
      for (final row in rows) {
        final item = row as Map<String, dynamic>;
        _wishes[item['wish_date'].toString()] = item['wish_type'].toString();
      }

      setState(() {
        _period = period;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить пожелания';
        _loading = false;
      });
    }
  }

  List<DateTime> _days() {
    final start = DateTime.parse(_period!['start_date'].toString());
    final end = DateTime.parse(_period!['end_date'].toString());
    return [
      for (var d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1)))
        DateTime(d.year, d.month, d.day),
    ];
  }

  Future<void> _setWish(DateTime day, String type) async {
    final key = day.toIso8601String().split('T').first;
    final old = _wishes[key];

    setState(() => _wishes[key] = type);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wishes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'period_id': _period!['id'],
          'user_id': _userId,
          'wish_date': key,
          'wish_type': type,
        }),
      );
      if (response.statusCode != 200) {
        setState(() {
          if (old == null) {
            _wishes.remove(key);
          } else {
            _wishes[key] = old;
          }
        });
      }
    } catch (_) {
      setState(() {
        if (old == null) {
          _wishes.remove(key);
        } else {
          _wishes[key] = old;
        }
      });
    }
  }

  String _label(DateTime day) {
    const names = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return '${names[day.weekday]}  ${day.day}.${day.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пожелания')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _period == null
                  ? const Center(child: Text('Набор пожеланий закрыт'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Text(
                          _period!['title'].toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('Отметь дни, когда хочешь или не можешь выйти'),
                        const SizedBox(height: 16),
                        ..._days().map((day) {
                          final key = day.toIso8601String().split('T').first;
                          final current = _wishes[key];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _label(day),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Хочу'),
                                      selected: current == 'want',
                                      onSelected: (_) => _setWish(day, 'want'),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Могу'),
                                      selected: current == 'can',
                                      onSelected: (_) => _setWish(day, 'can'),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Не могу'),
                                      selected: current == 'off',
                                      onSelected: (_) => _setWish(day, 'off'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
    );
  }
}