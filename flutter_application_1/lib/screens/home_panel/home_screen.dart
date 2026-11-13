import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/screens/reglog_panel/login_screen.dart';

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
  List<Map<String, dynamic>> _today = [];

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
      final peopleRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/employees'));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final barById = <int, String>{};
      if (peopleRes.statusCode == 200) {
        final body = jsonDecode(peopleRes.body) as Map<String, dynamic>;
        for (final row in (body['employees'] ?? []) as List<dynamic>) {
          final item = row as Map<String, dynamic>;
          final id = item['id'];
          if (id is int) barById[id] = (item['bar'] ?? '').toString();
        }
      }

      Map<String, dynamic>? next;
      final todayList = <Map<String, dynamic>>[];
      if (shiftsRes.statusCode == 200) {
        final body = jsonDecode(shiftsRes.body) as Map<String, dynamic>;
        for (final row in (body['shifts'] ?? []) as List<dynamic>) {
          final item = row as Map<String, dynamic>;
          final rawId = item['user_id'];
          final shiftUserId = rawId is int ? rawId : int.tryParse('$rawId');
          final parsed = DateTime.parse(item['date'].toString());
          final day = DateTime(parsed.year, parsed.month, parsed.day);
          final dateKey = item['date'].toString().substring(0, 10);
          final sameBar = AuthState.bar.isEmpty ||
              barById[shiftUserId] == AuthState.bar;

          if (shiftUserId == userId && !day.isBefore(today) && next == null) {
            next = item;
          }
          if (dateKey == todayKey && sameBar) {
            todayList.add(item);
          }
        }
      }

      var done = 0;
      var total = 0;
      if (coursesRes.statusCode == 200) {
        final body = jsonDecode(coursesRes.body) as Map<String, dynamic>;
        for (final row in (body['courses'] ?? []) as List<dynamic>) {
          final item = row as Map<String, dynamic>;
          done += (item['lessons_done'] as num?)?.toInt() ?? 0;
          total += (item['lessons_total'] as num?)?.toInt() ?? 0;
        }
      }

      setState(() {
        _nextShift = next;
        _today = todayList;
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Контакт Бар',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, size: 20),
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
                const SizedBox(height: 8),
                Text(
                  'Привет, $name',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text('$role · $bar', style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 28),
                _Card(
                  title: 'Ближайшая смена',
                  child: _nextShift == null
                      ? const Text('Смен пока нет')
                      : Text(
                          '${_nextShift!['date']}\n${_nextShift!['time']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 14),
                _Card(
                  title: 'Сегодня в смене',
                  child: _today.isEmpty
                      ? const Text('Сегодня в твоём баре никто не стоит')
                      : Column(
                          children: _today.map((item) {
                            final isMe = item['user_id'] == AuthState.id;
                            final title = isMe
                                ? '${item['name']} (вы)'
                                : '${item['name']}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(title)),
                                  Text('${item['time']}'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 14),
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
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