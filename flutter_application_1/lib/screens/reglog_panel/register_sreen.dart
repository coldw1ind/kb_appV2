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
  String? _selectedBar;
  final List<String> _roles = [
    'Официант',
    'Бармен',
    'Менеджер',
  ];
  List<String> _bars = const [
    'Дачный пр., 17к2',
    'Клочков пер., 6',
    'Коломяжский пр., 15к2',
    'пл. Стачек, 7',
    'ул. Марата, 7',
    'Владимирский пр., 17',
    'ул. Садовая, 35',
    'ул. Садовая, 41',
    'пр. Просвещения, 25',
    'Средний пр. В.О., 28',
    'пр. Чернышевского, 11',
    'ул. Бухарестская, 74',
    '2-я Красноармейская, 9/3',
    'Невский пр., 8',
    'пр. Науки, 23к2',
    'Гаккелевская ул., 34',
  ];

  static const _baseUrl = 'http://127.0.0.1:8000';

  @override
  void initState() {
    super.initState();
    _loadBars();
  }

  Future<void> _loadBars() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/bars'));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return;
      setState(() {
        _bars = List<String>.from(decoded);
      });
    } catch (_) {
      // оставляем локальный список баров
    }
  }

  void _goToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) {
        return const LoginScreen();
      }),
    );
  }

//Работа с БД НАЧАЛО
Future<String?> registerUser() async {
  final url = Uri.parse("$_baseUrl/register");

  if (_selectedRole == null) {
    return "Выбери роль";
  }

  if (_selectedBar == null) {
    return "Выбери бар";
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
        "bar": _selectedBar,
      }),
    );

    if (response.statusCode == 200) return null;
    return "Ошибка ${response.statusCode}: ${response.body}";
  } catch (e) {
    return "Нет связи с API: $e";
  }
}
//работы с БД КОНЕЦ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Как вас зовут',
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
                  isExpanded: true,
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
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBar,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  decoration: const InputDecoration(
                    labelText: 'Из какого вы бара',
                  ),
                  items: _bars.map((bar) {
                    return DropdownMenuItem(
                      value: bar,
                      child: Text(bar, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBar = value;
                    });
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final error = await registerUser();
                      if (!context.mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                        return;
                      }
                      _goToLoginScreen();
                    },
                    child: const Text('Зарегистрироваться'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
