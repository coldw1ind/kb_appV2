import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  Map<String, dynamic>? _nextShift;
  int _lessonsDone = 0;
  int _lessonsTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthState.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final shiftsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/shifts'));
      final coursesRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/courses?user_id=$userId'),
      );

      Map<String, dynamic>? next;
      if (shiftsRes.statusCode == 200) {
        final body = jsonDecode(shiftsRes.body) as Map<String, dynamic>;
        final rows = (body['shifts'] ?? []) as List<dynamic>;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        for (final row in rows) {
          final item = row as Map<String, dynamic>;
          if (item['user_id'] != userId) continue;
          final parsed = DateTime.parse(item['date'].toString());
          final day = DateTime(parsed.year, parsed.month, parsed.day);
          if (day.isBefore(today)) continue;
          next = item;
          break;
        }
      }

      var done = 0;
      var total = 0;
      if (coursesRes.statusCode == 200) {
        final body = jsonDecode(coursesRes.body) as Map<String, dynamic>;
        final rows = (body['courses'] ?? []) as List<dynamic>;
        for (final row in rows) {
          final item = row as Map<String, dynamic>;
          done += (item['lessons_done'] as num?)?.toInt() ?? 0;
          total += (item['lessons_total'] as num?)?.toInt() ?? 0;
        }
      }

      setState(() {
        _nextShift = next;
        _lessonsDone = done;
        _lessonsTotal = total;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthState.username.isEmpty ? 'коллега' : AuthState.username;
    final role = AuthState.role.isEmpty ? 'сотрудник' : AuthState.role;
    final bar = AuthState.bar.isEmpty ? 'бар не выбран' : AuthState.bar;
    final progress = _lessonsTotal == 0 ? 0.0 : _lessonsDone / _lessonsTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Привет, $name',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text('$role · $bar'),
                const SizedBox(height: 24),
                _Card(
                  title: 'Ближайшая смена',
                  child: _nextShift == null
                      ? const Text('Смен пока нет')
                      : Text(
                          '${_nextShift!['date']}\n${_nextShift!['time']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'Обучение',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_lessonsDone из $_lessonsTotal уроков'),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress, minHeight: 8),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}