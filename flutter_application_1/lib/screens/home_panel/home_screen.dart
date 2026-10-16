import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/auth_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AuthState.username.isEmpty ? 'коллега' : AuthState.username;
    final role = AuthState.role.isEmpty ? 'сотрудник' : AuthState.role;
    final bar = AuthState.bar.isEmpty ? 'бар не выбран' : AuthState.bar;

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Привет, $name',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(role),
            const SizedBox(height: 4),
            Text(bar),
            const SizedBox(height: 24),
            const Text('Ближайшая смена появится здесь, когда график утвердят.'),
          ],
        ),
      ),
    );
  }
}