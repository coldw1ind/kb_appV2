import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/calendar/month_calendar_screen.dart';
import 'package:flutter_application_1/screens/calendar/week_calendar_screen.dart';
import 'package:flutter_application_1/theme/app_colors.dart';

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
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  color: isMonthView ? AppColors.coral : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Месяц',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isMonthView ? Colors.white : AppColors.textHint,
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
                  color: !isMonthView ? AppColors.coral : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Неделя',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !isMonthView ? Colors.white : AppColors.textHint,
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
