import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TestsAdminScreen extends StatefulWidget {
  const TestsAdminScreen({super.key});

  @override
  State<TestsAdminScreen> createState() => _TestsAdminScreenState();
}

class _TestsAdminScreenState extends State<TestsAdminScreen> {
  static const _baseUrl = 'http://127.0.0.1:8000';
  static const _roles = ['Официант', 'Бармен', 'Менеджер', 'Управляющий'];

  final _sectionTitle = TextEditingController();
  final _testTitle = TextEditingController();
  String _role = 'Официант';
  List<Map<String, dynamic>> _sections = [];
  int? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    final all = <Map<String, dynamic>>[];
    for (final role in _roles) {
      final res = await http.get(Uri.parse('$_baseUrl/sections?role=$role'));
      if (res.statusCode != 200) continue;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      all.addAll(((body['sections'] ?? []) as List).cast<Map<String, dynamic>>());
    }
    if (!mounted) return;
    setState(() => _sections = all);
  }

  Future<void> _createSection() async {
    final title = _sectionTitle.text.trim();
    if (title.isEmpty) return;
    final res = await http.post(
      Uri.parse('$_baseUrl/sections'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'role': _role}),
    );
    if (res.statusCode == 200) {
      _sectionTitle.clear();
      await _loadSections();
    }
  }

  Future<void> _createTest() async {
    final title = _testTitle.text.trim();
    if (title.isEmpty || _selectedSection == null) return;
    final section = _sections.firstWhere((s) => s['id'] == _selectedSection);
    final res = await http.post(
      Uri.parse('$_baseUrl/tests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'section_id': _selectedSection,
        'title': title,
        'role': section['role'],
        'questions': [],
      }),
    );
    if (res.statusCode == 200) {
      _testTitle.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Тест создан')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Разделы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: _sectionTitle, decoration: const InputDecoration(labelText: 'Название раздела')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Роль'),
            items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _role = v ?? _role),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _createSection, child: const Text('Создать раздел')),
          const SizedBox(height: 32),
          const Text('Тест в раздел', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedSection,
            decoration: const InputDecoration(labelText: 'Раздел'),
            items: _sections
                .map((s) => DropdownMenuItem(
                      value: s['id'] as int,
                      child: Text('${s['title']} · ${s['role']}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSection = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _testTitle, decoration: const InputDecoration(labelText: 'Название теста')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _createTest, child: const Text('Добавить тест')),
        ],
      ),
    );
  }
}