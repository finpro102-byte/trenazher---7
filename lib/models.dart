enum GameMode { memo, multi, crowd }

enum Difficulty { easy, normal, hard }

class DiffSpec {
  const DiffSpec({
    required this.label,
    required this.memoShow,
    required this.memoOptions,
    required this.crowdBase,
    required this.crowdStep,
    required this.crowdMax,
    required this.crowdTime,
    required this.multiCount,
    required this.multiExtra,
  });

  final String label;

  /// Сколько секунд показываем лицо(а) на 1 уровне
  final double memoShow;

  /// Число вариантов ответа в режиме «Запомни лицо»
  final int Function(int level) memoOptions;

  /// Толпа: размер на 1 уровне / прирост за уровень / максимум
  final int crowdBase, crowdStep, crowdMax;

  /// Сколько секунд даётся на поиск в толпе на 1 уровне
  final double crowdTime;

  /// Сколько лиц нужно запомнить / сколько лишних в сетке («Несколько лиц»)
  final int Function(int level) multiCount;
  final int Function(int level) multiExtra;
}

int _memoEasy(int l) => (4 + l ~/ 2).clamp(4, 6);
int _memoNormal(int l) => (6 + l ~/ 2).clamp(6, 9);
int _memoHard(int l) => (8 + l ~/ 2).clamp(8, 12);
int _multiEasy(int l) => (2 + l ~/ 3).clamp(2, 3);
int _multiNormal(int l) => (2 + l ~/ 2).clamp(2, 4);
int _multiHard(int l) => (3 + l ~/ 2).clamp(3, 4);
int _extraEasy(int l) => 3 + l ~/ 2;
int _extraNormal(int l) => 4 + l ~/ 2;
int _extraHard(int l) => 5 + l ~/ 2;

extension DifficultySpec on Difficulty {
  DiffSpec get spec {
    switch (this) {
      case Difficulty.easy:
        return const DiffSpec(
          label: 'Лёгкий',
          memoShow: 4.0,
          memoOptions: _memoEasy,
          crowdBase: 8, crowdStep: 1, crowdMax: 14, crowdTime: 18,
          multiCount: _multiEasy, multiExtra: _extraEasy,
        );
      case Difficulty.normal:
        return const DiffSpec(
          label: 'Средний',
          memoShow: 3.0,
          memoOptions: _memoNormal,
          crowdBase: 10, crowdStep: 1, crowdMax: 18, crowdTime: 14,
          multiCount: _multiNormal, multiExtra: _extraNormal,
        );
      case Difficulty.hard:
        return const DiffSpec(
          label: 'Сложный',
          memoShow: 2.2,
          memoOptions: _memoHard,
          crowdBase: 12, crowdStep: 2, crowdMax: 24, crowdTime: 11,
          multiCount: _multiHard, multiExtra: _extraHard,
        );
    }
  }
}
