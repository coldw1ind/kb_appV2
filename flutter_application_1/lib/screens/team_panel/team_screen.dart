import 'package:flutter/material.dart';

const _bg = Color(0xFFFFF7F2);
const _ink = Color(0xFF1C1917);
const _muted = Color(0xFF78716C);
const _accent = Color(0xFFE85D4C);
const _line = Color(0xFFE7E0DA);

class TeamMember {
  const TeamMember(this.name, this.role, this.place, this.onShift, this.initials);
  final String name;
  final String role;
  final String place;
  final bool onShift;
  final String initials;
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final _people = const [
    TeamMember('Алексей Иванов', 'Бармен', 'Контакт Бар • Центр', true, 'АИ'),
    TeamMember('Мария Смирнова', 'Официант', 'Контакт Бар • Центр', true, 'МС'),
    TeamMember('Дмитрий Орлов', 'Бармен', 'Контакт Бар • Центр', false, 'ДО'),
    TeamMember('Анна Кузнецова', 'Менеджер', 'Контакт Бар • Центр', true, 'АК'),
  ];

  String _query = '';
  String _filter = 'Все';

  @override
  Widget build(BuildContext context) {
    final filters = ['Все', 'Бармен', 'Официант', 'Менеджер'];
    final list = _people.where((p) {
      final byName = p.name.toLowerCase().contains(_query.toLowerCase());
      final byRole = _filter == 'Все' || p.role == _filter;
      return byName && byRole;
    }).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Наша команда',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
                  SizedBox(height: 6),
                  Text('Люди, которые делают Контакт Бар',
                      style: TextStyle(color: _muted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Найти сотрудника',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: filters.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: _accent,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : _ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = list[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _accent.withOpacity(0.15),
                          child: Text(p.initials, style: const TextStyle(color: _accent, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${p.role}  •  ${p.place}',
                                  style: const TextStyle(color: _muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          p.onShift ? 'На смене' : 'Выходной',
                          style: TextStyle(
                            color: p.onShift ? const Color(0xFF16A34A) : _muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}