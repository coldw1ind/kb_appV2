import 'package:flutter/material.dart';
import 'schedule_grid_screen.dart';
import 'tests_admin_screen.dart';
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      ScheduleGridScreen(),
      TestsAdminScreen(),
      Center(child: Text('Сотрудники — скоро')),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() => _index = value);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('График'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                label: Text('Курсы'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                label: Text('Сотрудники'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }
}