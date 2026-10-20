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
  
  List<Map<String, dynamic>> _employees = []; // Все сотрудники бара
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
      // 1. Загружаем текущий период
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

      // 2. Загружаем сотрудников (только своего бара)
      final empRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/employees'));
      final empBody = jsonDecode(empRes.body) as Map<String, dynamic>;
      final allEmps = (empBody['employees'] ?? []) as List;
      final myBar = AuthState.bar;
      
      final filteredEmps = allEmps
          .cast<Map<String, dynamic>>()
          .where((e) => myBar.isEmpty || (e['bar'] ?? '').toString() == myBar)
          .toList();

      // 3. Загружаем пожелания и черновики
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
    if (wish?['wish_type'] == 'off') return; // Нельзя ставить смену, если "Не может"

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

  Widget _buildDateList() {
    final days = _days();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dateStr = _dateKey(day);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(
              _formatDateHuman(day),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            subtitle: Text(
              '${_employees.where((e) => _wishFor(e['id'] as int, dateStr) != null).length} пожеланий',
              style: const TextStyle(fontSize: 13),
            ),
            children: _employees.map((emp) {
              final userId = emp['id'] as int;
              final username = emp['username'].toString();
              final wish = _wishFor(userId, dateStr);
              final draft = _draftFor(userId, dateStr);

              return _buildEmployeeTile(userId, username, dateStr, wish, draft);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeTile(
    int userId, 
    String username, 
    String date, 
    Map<String, dynamic>? wish, 
    Map<String, dynamic>? draft
  ) {
    final wishType = wish?['wish_type'];
    
    // Определяем цвет и текст для пожелания (только Может / Не может)
    Color wishColor = Colors.grey;
    String wishText = 'Нет пожеланий';
    
    if (wishType == 'can') {
      wishColor = Colors.green; // Зеленый, как в календаре
      wishText = 'Может';
    } else if (wishType == 'off') {
      wishColor = Colors.red;
      wishText = 'Не может';
    }

    final canEdit = _period!['status'] == 'manager_review' || _period!['status'] == 'director_review';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(username),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: wishColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(wishText, style: TextStyle(color: wishColor, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
      trailing: draft != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${draft['time']}',
                style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          : (canEdit && wishType != 'off' 
              ? TextButton(
                  onPressed: () => _editCell(userId, username, date),
                  child: const Text('В смену'),
                )
              : const SizedBox.shrink()),
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