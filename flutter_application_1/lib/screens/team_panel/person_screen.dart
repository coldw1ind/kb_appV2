import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';

class PersonScreen extends StatefulWidget {
  final int userId;
  final String name;
  final String role;
  final String bar;

  const PersonScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.role,
    required this.bar,
  });

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _week = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/shifts'));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      final list = <Map<String, dynamic>>[];
      for (final row in (body['shifts'] ?? []) as List<dynamic>) {
        final item = row as Map<String, dynamic>;
        if (item['user_id'] != widget.userId) continue;
        final day = DateTime.parse(item['date'].toString());
        final date = DateTime(day.year, day.month, day.day);
        if (date.isBefore(monday) || date.isAfter(sunday)) continue;
        list.add(item);
      }
      list.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
      setState(() => _week = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.role, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.bar),
          const SizedBox(height: 24),
          const Text('Смены на этой неделе', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_loading)
            const CircularProgressIndicator()
          else if (_week.isEmpty)
            const Text('На этой неделе смен нет')
          else
            ..._week.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(item['date'].toString().substring(0, 10)),
                    subtitle: Text('${item['time']} · ${item['role']}'),
                  ),
                )),
        ],
      ),
    );
  }
}