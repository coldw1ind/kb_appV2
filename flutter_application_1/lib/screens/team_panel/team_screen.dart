import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/screens/team_panel/person_screen.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _people = [];
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
        Uri.parse('${ApiConfig.baseUrl}/employees'),
      );
      if (response.statusCode != 200) {
        throw Exception('Ошибка ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['employees'] ?? []) as List<dynamic>;
      final myBar = AuthState.bar;

      final people = rows
          .cast<Map<String, dynamic>>()
          .where((p) => myBar.isEmpty || (p['bar'] ?? '').toString() == myBar)
          .toList();

      setState(() {
        _people = people;
        _loading = false;
      });
    } catch (_) {
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
      appBar: AppBar(title: const Text('Команда')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthState.bar.isEmpty ? 'Все точки' : AuthState.bar,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Поиск по имени',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) => setState(() => _query = value),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: filters.map((f) {
                              return ChoiceChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(child: Text('Никого не нашли'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = list[index];
                                final name = (p['username'] ?? '').toString();
                                final role = (p['employee_role'] ?? '').toString();
                                final id = p['id'];
                                final isMe = id == AuthState.id;
                                return ListTile(
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  leading: CircleAvatar(
                                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                                  ),
                                  title: Text(isMe ? '$name (вы)' : name),
                                  subtitle: Text(role),
                                  // ↓↓↓ ДОБАВЛЕН onTap ↓↓↓
                                  onTap: () {
                                    final rawId = p['id'];
                                    final id = rawId is int ? rawId : int.tryParse('$rawId');
                                    if (id == null) return;
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PersonScreen(
                                          userId: id,
                                          name: name,
                                          role: role,
                                          bar: (p['bar'] ?? AuthState.bar).toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  // ↑↑↑ КОНЕЦ onTap ↑↑↑
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}