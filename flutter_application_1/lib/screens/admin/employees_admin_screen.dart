import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmployeesAdminScreen extends StatefulWidget {
  const EmployeesAdminScreen({super.key});

  @override
  State<EmployeesAdminScreen> createState() => _EmployeesAdminScreenState();
}

class _EmployeesAdminScreenState extends State<EmployeesAdminScreen> {
  List<Map<String, dynamic>> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:8000/employees'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _people = ((body['employees'] ?? []) as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(24),
      children: _people
          .map((p) => ListTile(
                title: Text(p['username'].toString()),
                subtitle: Text('${p['employee_role']} · ${p['bar']}'),
              ))
          .toList(),
    );
  }
}