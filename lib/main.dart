import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'models.dart';

void main() => runApp(const FaceHuntApp());

class FaceHuntApp extends StatelessWidget {
  const FaceHuntApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Тренажёр 7',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const MenuScreen(),
      );
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Difficulty _difficulty = Difficulty.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тренажёр 7')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Уровень сложности',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Difficulty>(
            segments: const [
              ButtonSegment(
                  value: Difficulty.easy, label: Text('Лёгкий')),
              ButtonSegment(
                  value: Difficulty.normal, label: Text('Средний')),
              ButtonSegment(
                  value: Difficulty.hard, label: Text('Сложный')),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) =>
                setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 24),
          _ModeCard(
            icon: Icons.face,
            title: 'Запомни лицо',
            badge: '1 цель',
            desc:
                'Лицо покажут на несколько секунд — затем выбери его среди вариантов.',
            onTap: () => _open(GameMode.memo),
          ),
          _ModeCard(
            icon: Icons.groups,
            title: 'Запомни несколько лиц',
            badge: '2–4 цели',
            desc:
                'Запомни группу людей и отметь каждого из них в общей сетке.',
            onTap: () => _open(GameMode.multi),
          ),
          _ModeCard(
            icon: Icons.travel_explore,
            title: 'Найди в толпе',
            badge: 'на время',
            desc:
                'Отыщи заданного человека в толпе. Толпа растёт, время тает.',
            onTap: () => _open(GameMode.crowd),
          ),
        ],
      ),
    );
  }

  void _open(GameMode mode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          GameScreen(mode: mode, difficulty: _difficulty),
    ));
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title, badge, desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Row(
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text(badge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
          ],
        ),
        subtitle: Text(desc),
        onTap: onTap,
      ),
    );
  }
}
