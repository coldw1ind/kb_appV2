import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/calendar/month_calendar_screen.dart';
import 'package:flutter_application_1/screens/calendar/week_calendar_screen.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  bool _isMonthView = true;

  @override
  Widget build(BuildContext context) {
    if (_isMonthView) {
      return CalendarScreen(
        onSwitchToWeek: () => setState(() => _isMonthView = false),
      );
    }

    return WeekCalendarScreen(
      onSwitchToMonth: () => setState(() => _isMonthView = true),
    );
  }
}

class CalendarChange extends StatelessWidget {
  final bool isMonthView;
  final ValueChanged<bool> onViewChanged;

  const CalendarChange({
    super.key,
    required this.isMonthView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFFF6B6B);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onViewChanged(true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMonthView ? coral : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Месяц',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isMonthView ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onViewChanged(false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isMonthView ? coral : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Неделя',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !isMonthView ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}