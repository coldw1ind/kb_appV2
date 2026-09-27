import 'package:flutter/material.dart';
import 'screens/admin/admin_shell.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Контакт Бар — панель',
      home: AdminShell(),
    );
  }
}