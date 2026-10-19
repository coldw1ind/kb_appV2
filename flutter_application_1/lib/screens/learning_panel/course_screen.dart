import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';

class CourseScreen extends StatefulWidget {
  final int courseId;
  final String title;
  final int total;
  final int done;

  const CourseScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.total,
    required this.done,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late int _done;

  @override
  void initState() {
    super.initState();
    _done = widget.done;
  }

  Future<void> _toggle(int index) async {
    final userId = AuthState.id;
    if (userId == null) return;
    final next = index < _done ? index : index + 1;
    setState(() => _done = next);
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/courses/${widget.courseId}/progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'lessons_done': next}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: widget.total,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final passed = index < _done;
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Icon(passed ? Icons.check_circle : Icons.circle_outlined),
            title: Text('Урок ${index + 1}'),
            onTap: () => _toggle(index),
          );
        },
      ),
    );
  }
}