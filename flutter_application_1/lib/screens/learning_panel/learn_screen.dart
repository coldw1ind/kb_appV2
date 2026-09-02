import 'package:flutter/material.dart';

const _bg = Color(0xFFFFF7F2);
const _ink = Color(0xFF1C1917);
const _muted = Color(0xFF78716C);
const _accent = Color(0xFFE85D4C);
const _soft = Color(0xFFFFF0EC);
const _navy = Color(0xFF2B2A4A);

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = const [
      ['Барная карта', 4, 8],
      ['Стандарты сервиса', 6, 8],
      ['Коктейли', 2, 10],
      ['Безопасность', 3, 5],
      ['Работа с гостями', 0, 6],
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Обучение',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 6),
            const Text('Развивай навыки вместе с Контакт Бар',
                style: TextStyle(color: _muted)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(20)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ваш прогресс', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    child: LinearProgressIndicator(
                      value: 0.72,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      color: _accent,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('72%  •  8 из 11 курсов', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _Cat('🍸', 'Бар'),
                  _Cat('🍽', 'Кухня'),
                  _Cat('📋', 'Стандарты'),
                  _Cat('🤝', 'Сервис'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Продолжить обучение', style: TextStyle(color: _muted)),
                  const SizedBox(height: 6),
                  const Text('Барная карта', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Урок 4 из 8', style: TextStyle(color: _muted)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                    child: const Text('Продолжить'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...courses.map((c) {
              final done = c[1] as int;
              final total = c[2] as int;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c[0] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('$done из $total уроков', style: const TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: done / total,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE7E0DA),
                      color: _accent,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Cat extends StatelessWidget {
  const _Cat(this.emoji, this.title);
  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}