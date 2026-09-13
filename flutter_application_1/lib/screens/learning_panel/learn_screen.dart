import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _bg = Color(0xFFFFF7F2);
const _ink = Color(0xFF1C1917);
const _muted = Color(0xFF78716C);
const _accent = Color(0xFFE85D4C);
const _soft = Color(0xFFFFF0EC);
const _navy = Color(0xFF2B2A4A);

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  static const _userId = 1;
  static const _baseUrl = 'http://127.0.0.1:8000';

  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses?user_id=$_userId'),
      );
      if (response.statusCode != 200) {
        setState(() => _loading = false);
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['courses'] ?? []) as List<dynamic>;

      setState(() {
        _courses = rows.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      print('COURSES ERROR: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final started = _courses.where((c) => (c['lessons_done'] as num) > 0).length;
    final totalCourses = _courses.length;
    final progress = totalCourses == 0 ? 0.0 : started / totalCourses;

    Map<String, dynamic>? continueCourse;
    for (final course in _courses) {
      final done = (course['lessons_done'] as num).toInt();
      final total = (course['lessons_total'] as num).toInt();
      if (done > 0 && done < total) {
        continueCourse = course;
        break;
      }
    }

    final categories = _courses
        .map((c) => c['category'].toString())
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text(
                    'Обучение',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Развивай навыки вместе с Контакт Бар',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ваш прогресс',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(99)),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white24,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(progress * 100).round()}%  •  $started из $totalCourses курсов',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: categories
                          .map((title) => _Cat('•', title))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (continueCourse != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Продолжить обучение', style: TextStyle(color: _muted)),
                          const SizedBox(height: 6),
                          Text(
                            continueCourse['title'].toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Урок ${continueCourse['lessons_done']} из ${continueCourse['lessons_total']}',
                            style: const TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(backgroundColor: _accent),
                            child: const Text('Продолжить'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ..._courses.map((c) {
                    final done = (c['lessons_done'] as num).toInt();
                    final total = (c['lessons_total'] as num).toInt();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$done из $total уроков',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: total == 0 ? 0 : done / total,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE7E0DA),
                            color: _accent,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}

class _Cat extends StatelessWidget {
  const _Cat(this.emoji, this.title);
  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}