import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/auth_state.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final role = AuthState.role;
    if (role.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/sections?role=$role'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _sections = ((body['sections'] ?? []) as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text('Обучение', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  if (_sections.isEmpty)
                    const Text('Пока нет разделов')
                  else
                    ..._sections.map((s) => ListTile(
                          title: Text(s['title'].toString()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _SectionScreen(
                                  sectionId: s['id'] as int,
                                  title: s['title'].toString(),
                                ),
                              ),
                            );
                          },
                        )),
                ],
              ),
      ),
    );
  }
}

class _SectionScreen extends StatefulWidget {
  final int sectionId;
  final String title;
  const _SectionScreen({required this.sectionId, required this.title});

  @override
  State<_SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<_SectionScreen> {
  List<Map<String, dynamic>> _tests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await http.get(Uri.parse('http://127.0.0.1:8000/tests?section_id=${widget.sectionId}'));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    setState(() => _tests = ((body['tests'] ?? []) as List).cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _tests.isEmpty
          ? const Center(child: Text('В разделе пока нет тестов'))
          : ListView(
              children: _tests
                  .map((t) => ListTile(title: Text(t['title'].toString())))
                  .toList(),
            ),
    );
  }
}