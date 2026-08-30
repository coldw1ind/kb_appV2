import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/reglog_panel/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:logging/logging.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  String? _selectedRole;
  final List<String> _roles = [
    'Официант',
    'Бармен',
    'Менеджер',
  ];

  void _goToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) {
        return const LoginScreen();
      }),
    );
  }

//Работа с БД НАЧАЛО
Future<bool> registerUser() async {
  const baseUrl = "http://127.0.0.1:8000"; // Android emulator: http://10.0.2.2:8000
  final url = Uri.parse("$baseUrl/register");

  if (_selectedRole == null) {
    print("Роль не выбрана");
    return false;
  }

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "employee_role": _selectedRole,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  } catch (e) {
    print("REQUEST ERROR: $e");
    return false;
  }
}
//работы с БД КОНЕЦ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Как вас зовут'
              ),
            ),

            const SizedBox(height: 9),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),

            const SizedBox(height: 9),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),

            const SizedBox(height: 9),

            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Роль',
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async{
                  final ok = await registerUser();
                  if (!ok) return;
                    _goToLoginScreen();
                },
                child: const Text('Зарегистрироваться'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
