import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _people = [];
  String _query = '';
  String _filter = 'Все';

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
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/employees'),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      setState(() {
        _people = body['employees'] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить команду';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Все', 'Официант', 'Бармен', 'Менеджер'];

    final list = _people.where((p) {
      final name = (p['username'] ?? '').toString();
      final role = (p['employee_role'] ?? '').toString();
      final byName = name.toLowerCase().contains(_query.toLowerCase());
      final byRole = _filter == 'Все' || role == _filter;
      return byName && byRole;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Наша команда',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Сотрудники из базы',
                style: TextStyle(color: Color(0xFF78716C)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Найти сотрудника',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: filters.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : list.isEmpty
                          ? const Center(child: Text('Пока никто не зарегистрирован'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final p = list[i];
                                final name = (p['username'] ?? '').toString();
                                final role = (p['employee_role'] ?? '').toString();

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          name.isEmpty ? '?' : name[0].toUpperCase(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                            Text(
                                              role,
                                              style: const TextStyle(color: Color(0xFF78716C)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}