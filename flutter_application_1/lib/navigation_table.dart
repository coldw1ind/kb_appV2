import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/achievements/achievements_screen.dart';
import 'package:flutter_application_1/screens/calendar/month_or_week.dart';
import 'package:flutter_application_1/screens/reglog_panel/login_screen.dart';
import 'package:flutter_application_1/screens/learning/learn_screen.dart';
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CalendarTab(),
    const LearningScreen(),
    const AchievementsScreen(),
    const CalendarTab(),
    const LoginScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 35),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book, size: 35),
            label: 'Обучение',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star, size: 35),
            label: 'Достижения',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, size: 35),
            label: 'График',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 35),
            label: 'Команда',
          ),
        ],
      ),
    );
  }
}
