import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/api/api_config.dart';
import 'package:flutter_application_1/api/auth_state.dart';
import 'package:flutter_application_1/theme/app_colors.dart';

class ScheduleGridScreen extends StatefulWidget {
  const ScheduleGridScreen({super.key});

  @override
  State<ScheduleGridScreen> createState() => _ScheduleGridScreenState();
}

class _ScheduleGridScreenState extends State<ScheduleGridScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _period;
  
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _wishes = [];
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final periodRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/periods/current'));
      final periodBody = jsonDecode(periodRes.body) as Map<String, dynamic>;
      final period = periodBody['period'] as Map<String, dynamic>?;

      if (period == null) {
        setState(() {
          _period = null;
          _loading = false;
        });
        return;
      }

      final id = period['id'];

      final empRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/employees'));
      final empBody = jsonDecode(empRes.body) as Map<String, dynamic>;
      final allEmps = (empBody['employees'] ?? []) as List;
      final myBar = AuthState.bar;
      
      final filteredEmps = allEmps
          .cast<Map<String, dynamic>>()
          .where((e) => myBar.isEmpty || (e['bar'] ?? '').toString() == myBar)
          .toList();

      final wishesRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/wishes?period_id=$id'));
      final draftsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/draft-shifts?period_id=$id'));

      setState(() {
        _period = period;
        _employees = filteredEmps;
        _wishes = ((jsonDecode(wishesRes.body)['wishes'] ?? []) as List).cast<Map<String, dynamic>>();
        _drafts = ((jsonDecode(draftsRes.body)['draft_shifts'] ?? []) as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные';
        _loading = false;
      });
    }
  }

  List<DateTime> _days() {
    final start = DateTime.parse(_period!['start_date'].toString());
    final end = DateTime.parse(_period!['end_date'].toString());
    return [
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1)))
        DateTime(d.year, d.month, d.day),
    ];
  }

  String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  String _formatDateHuman(DateTime day) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'мая', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
    ];
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return '${weekdays[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';
  }

  Map<String, dynamic>? _wishFor(int userId, String date) {
    for (final wish in _wishes) {
      if (wish['user_id'] == userId && wish['wish_date'].toString() == date) {
        return wish;
      }
    }
    return null;
  }

  Map<String, dynamic>? _draftFor(int userId, String date) {
    for (final draft in _drafts) {
      if (draft['user_id'] == userId && draft['shift_date'].toString() == date) {
        return draft;
      }
    }
    return null;
  }

  Future<void> _editCell(int userId, String username, String date) async {
    final wish = _wishFor(userId, date);
    if (wish?['wish_type'] == 'off') return;

    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '18:00');
    String role = 'Официант';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$username\n$date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Начало'),
              ),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'Конец'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: 'Официант', child: Text('Официант')),
                  DropdownMenuItem(value: 'Бармен', child: Text('Бармен')),
                ],
                onChanged: (value) {
                  if (value != null) role = value;
                },
                decoration: const InputDecoration(labelText: 'Роль'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Поставить'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/draft-shifts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'period_id': _period!['id'],
        'user_id': userId,
        'shift_date': date,
        'start_time': startController.text.trim(),
        'end_time': endController.text.trim(),
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      appBar: AppBar(
        title: const Text('Сборка графика'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _period == null
                  ? const Center(child: Text('Нет открытого периода'))
                  : Column(
                      children: [
                        _buildHeader(),
                        Expanded(child: _buildDateList()),
                        _buildBottomButtons(),
                      ],
                    ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _period!['title'].toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _period!['status'].toString().toUpperCase(),
              style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ↓↓↓ ЗАМЕНЕНО НА СПИСОК МЕСЯЦЕВ С СЕТКАМИ ДНЕЙ ↓↓↓
  Widget _buildDateList() {
    final days = _days();
    if (days.isEmpty) return const SizedBox.shrink();

    final byMonth = <String, List<DateTime>>{};
    for (final day in days) {
      final key = '${day.year}-${day.month}';
      byMonth.putIfAbsent(key, () => []).add(day);
    }

    const weekdays = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    const months = ['', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: byMonth.entries.map((entry) {
        final monthDays = entry.value;
        final first = monthDays.first;
        final leading = first.weekday - 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                '${months[first.month]} ${first.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: leading + monthDays.length,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day = monthDays[index - leading];
                final date = _dateKey(day);
                final count = _wishes.where((w) => w['wish_date'].toString().startsWith(date)).length;
                return InkWell(
                  onTap: () => _openDay(day, date),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekdays[day.weekday], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const Spacer(),
                        Text('${day.day}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(count == 0 ? 'пусто' : '$count чел.', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  // _openDay оставлен без изменений
  void _openDay(DateTime day, String date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_formatDateHuman(day)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _employees.map((emp) {
              final userId = emp['id'] as int;
              final username = emp['username'].toString();
              final wish = _wishFor(userId, date);
              final draft = _draftFor(userId, date);
              final wishType = wish?['wish_type'];

              Color wishColor = Colors.grey;
              String wishText = 'Нет пожеланий';
              if (wishType == 'want') { wishColor = Colors.orange; wishText = 'Хочет'; }
              else if (wishType == 'can') { wishColor = Colors.green; wishText = 'Может'; }
              else if (wishType == 'off') { wishColor = Colors.red; wishText = 'Не может'; }

              final canEdit = _period!['status'] == 'manager_review' || _period!['status'] == 'director_review';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(username),
                subtitle: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: wishColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(wishText, style: TextStyle(color: wishColor, fontSize: 13)),
                  ],
                ),
                trailing: draft != null 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                        child: Text('${draft['time']}', style: const TextStyle(color: Color(0xFF047857), fontSize: 12)),
                      )
                    : (canEdit && wishType != 'off' 
                        ? TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _editCell(userId, username, date);
                            },
                            child: const Text('В смену'),
                          )
                        : const SizedBox.shrink()),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_period!['status'] == 'collecting')
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await http.post(Uri.parse('${ApiConfig.baseUrl}/periods/${_period!['id']}/close-wishes'));
                  await _load();
                },
                child: const Text('Закрыть набор'),
              ),
            ),
          if (_period!['status'] == 'manager_review')
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await http.post(Uri.parse('${ApiConfig.baseUrl}/periods/${_period!['id']}/send-to-director'));
                  await _load();
                },
                child: const Text('Отправить управляющему'),
              ),
            ),
          if (_period!['status'] == 'director_review')
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await http.post(Uri.parse('${ApiConfig.baseUrl}/periods/${_period!['id']}/publish'));
                  await _load();
                },
                child: const Text('Утвердить график'),
              ),
            ),
        ],
      ),
    );
  }
}