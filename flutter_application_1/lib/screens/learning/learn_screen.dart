import 'package:flutter/material.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // Константы цветов
  static const _bg = Color(0xFFFFF7F2);
  static const _ink = Color(0xFF1C1917);
  static const _muted = Color(0xFF78716C);
  static const _accent = Color(0xFFE85D4C);
  static const _soft = Color(0xFFFFF0EC);
  static const _navy = Color(0xFF2B2A4A);

  // Данные курсов (теперь можно изменять в будущем)
  final List<Map<String, dynamic>> _courses = [
    {'title': 'Барная карта', 'done': 4, 'total': 8},
    {'title': 'Стандарты сервиса', 'done': 6, 'total': 8},
    {'title': 'Коктейли', 'done': 2, 'total': 10},
    {'title': 'Безопасность', 'done': 3, 'total': 5},
    {'title': 'Работа с гостями', 'done': 0, 'total': 6},
  ];

  // Данные прогресса (можно обновлять)
  double _overallProgress = 0.72;
  int completedCourses = 8;
  int totalCourses = 11;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Обучение',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Развивай навыки вместе с Контакт Бар',
              style: TextStyle(color: _muted, fontSize: 15),
            ),
            const SizedBox(height: 18),
            _buildProgressCard(),
            const SizedBox(height: 16),
            _buildCategoriesList(),
            const SizedBox(height: 16),
            _buildContinueLearningCard(),
            const SizedBox(height: 18),
            const Text(
              'Курсы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ..._courses.map((course) => _buildCourseCard(course)),
          ],
        ),
      ),
    );
  }

  // Виджет карточки прогресса
  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваш прогресс',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(_overallProgress * 100).round()}%  •  $completedCourses из $totalCourses курсов',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // Горизонтальный список категорий
  Widget _buildCategoriesList() {
    const categories = [
      {'emoji': '🍸', 'title': 'Бар'},
      {'emoji': '🍽', 'title': 'Кухня'},
      {'emoji': '📋', 'title': 'Стандарты'},
      {'emoji': '🤝', 'title': 'Сервис'},
      {'emoji': '🧠', 'title': 'Компания'},
    ];

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories
            .map((cat) => _CategoryCard(
                  emoji: cat['emoji'] as String,
                  title: cat['title'] as String,
                ))
            .toList(),
      ),
    );
  }

  // Карточка "Продолжить обучение"
  Widget _buildContinueLearningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Продолжить обучение', style: TextStyle(color: _muted)),
          const SizedBox(height: 6),
          const Text(
            'Барная карта',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text('Урок 4 из 8', style: TextStyle(color: _muted)),
          const SizedBox(height: 12),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: _accent,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _handleContinueLearning,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }

  // Карточка курса
  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['title'] as String;
    final done = course['done'] as int;
    final total = course['total'] as int;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$done из $total уроков',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: const Color(0xFFE7E0DA),
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  // Обработчик нажатия "Продолжить"
  void _handleContinueLearning() {
    // Здесь можно добавить логику перехода к уроку
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Открываем урок...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Метод для обновления прогресса (пример использования state)
  void updateProgress(double newProgress) {
    setState(() {
      _overallProgress = newProgress;
    });
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.title,
  });

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}