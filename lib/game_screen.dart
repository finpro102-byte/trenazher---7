import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'face_provider.dart';
import 'models.dart';

enum _Phase { loading, show, pick, feedback, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode, required this.difficulty});

  final GameMode mode;
  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // Все портреты включаются в APK: игра работает без интернета.
  final FaceProvider _provider = AssetFaceProvider(count: 60);
  final _rng = Random();

  late final AnimationController _timerCtrl;
  Timer? _delay;

  _Phase _phase = _Phase.loading;
  List<Face> _targets = const [];
  List<Face> _options = const [];
  final _found = <String>{};
  final _wrong = <String>{};

  int _level = 1, _score = 0, _lives = 3, _streak = 0;
  String _feedback = '';
  bool _feedbackGood = false;
  double _showSeconds = 3;
  double _findSeconds = 12;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onCountdownEnd();
      });
    _startRound();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _timerCtrl.dispose();
    super.dispose();
  }

  DiffSpec get _spec => widget.difficulty.spec;

  int get _basePoints => switch (widget.mode) {
        GameMode.memo => 10,
        GameMode.multi => 15,
        GameMode.crowd => 12,
      };

  double get _combo => 1 + min(_streak, 4) * 0.5;

  String get _modeTitle => switch (widget.mode) {
        GameMode.memo => 'Запомни лицо',
        GameMode.multi => 'Несколько лиц',
        GameMode.crowd => 'Найди в толпе',
      };

  /* -------------------- Раунды -------------------- */

  Future<void> _startRound() async {
    _delay?.cancel();
    _timerCtrl.stop();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.loading;
      _feedback = '';
      _found.clear();
      _wrong.clear();
    });
    try {
      switch (widget.mode) {
        case GameMode.memo:
          final total = _spec.memoOptions(_level);
          final t = await _provider.nextFace();
          final rest = await _provider.nextFaces(total - 1);
          _targets = [t];
          _options = [t, ...rest];
          _showSeconds = max(1.1, _spec.memoShow - _level * 0.15);
        case GameMode.multi:
          final n = _spec.multiCount(_level);
          _targets = await _provider.nextFaces(n);
          final extra = await _provider.nextFaces(_spec.multiExtra(_level));
          _options = [..._targets, ...extra];
          _showSeconds = max(1.6, _spec.memoShow + n - _level * 0.2);
        case GameMode.crowd:
          final t = await _provider.nextFace();
          final size =
              min(_spec.crowdBase + _level * _spec.crowdStep, _spec.crowdMax);
          _targets = [t];
          _options = [t, ...await _provider.nextFaces(size - 1)];
          _showSeconds = 1.6; // время на запоминание цели
          _findSeconds = max(4.0, _spec.crowdTime - _level * 0.6);
      }
      _options = [..._options]..shuffle(_rng);
      await _precache(_options);
      if (!mounted) return;
      _enterPhase(_Phase.show, seconds: _showSeconds);
    } catch (e) {
      if (!mounted) return;
      setState(() => _feedback = 'Не удалось загрузить лица: $e');
    }
  }

  Future<void> _precache(List<Face> faces) => Future.wait(
        faces.map((f) async {
          try {
            await precacheImage(f.image, context);
          } catch (_) {
            // отдельная ячейка покажет заглушку — игра не сломается
          }
        }),
      );

  void _enterPhase(_Phase p, {double? seconds}) {
    setState(() => _phase = p);
    if (seconds != null) {
      _timerCtrl.duration =
          Duration(milliseconds: (seconds * 1000).round());
      _timerCtrl.forward(from: 0);
    } else {
      _timerCtrl.stop();
    }
  }

  void _onCountdownEnd() {
    if (_phase == _Phase.show) {
      _enterPhase(_Phase.pick,
          seconds: widget.mode == GameMode.crowd ? _findSeconds : null);
    } else if (_phase == _Phase.pick) {
      _lose('Время вышло!');
    }
  }

  void _onCellTap(Face f) {
    if (_phase != _Phase.pick) return;
    final isTarget = _targets.any((t) => t.id == f.id);
    if (isTarget && !_found.contains(f.id)) {
      setState(() => _found.add(f.id));
      final allFound = _targets.every((t) => _found.contains(t.id));
      if (allFound) _win();
    } else if (!isTarget && !_wrong.contains(f.id)) {
      setState(() => _wrong.add(f.id));
      _lose('Не тот человек!');
    }
  }

  void _win() {
    _streak++;
    final pts = (_basePoints * _level * _combo).round();
    _score += pts;
    _level++;
    _timerCtrl.stop();
    setState(() {
      _phase = _Phase.feedback;
      _feedbackGood = true;
      _feedback = 'Верно! +$pts'
          '${_streak > 1 ? ' (комбо ×${_combo.toStringAsFixed(1)})' : ''}';
    });
    _delay = Timer(const Duration(milliseconds: 1000), _startRound);
  }

  void _lose(String msg) {
    _streak = 0;
    _lives--;
    _timerCtrl.stop();
    setState(() {
      _phase = _Phase.feedback;
      _feedbackGood = false;
      _feedback = '$msg Жизней: $_lives';
    });
    _delay = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_lives <= 0) {
        setState(() => _phase = _Phase.gameOver);
      } else {
        _startRound();
      }
    });
  }

  /* -------------------- UI -------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_modeTitle · ${_spec.label}'),
        actions: [
          Center(
            child: Text(
              '${'❤' * _lives}${'🖤' * (3 - _lives)}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Очки $_score · Ур. $_level')),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AnimatedBuilder(
              animation: _timerCtrl,
              builder: (c, _) => LinearProgressIndicator(
                value: _timerCtrl.duration == null ? null : _timerCtrl.value,
                minHeight: 5,
              ),
            ),
          ),
          Expanded(child: _body()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              _feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _feedbackGood ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Загружаем фотографии лиц…'),
            ],
          ),
        );
      case _Phase.gameOver:
        return _gameOver();
      case _Phase.show:
        return _showTargets();
      case _Phase.pick:
      case _Phase.feedback:
        return _pickGrid();
    }
  }

  Widget _faceImage(Face f) {
    return Image(
      image: f.image,
      fit: BoxFit.cover,
      loadingBuilder: (c, w, p) => p == null
          ? w
          : const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
      errorBuilder: (c, e, s) => Container(
        color: Colors.black12,
        child: const Icon(Icons.person_outline, size: 32),
      ),
    );
  }

  Widget _showTargets() {
    final prompt = switch (widget.mode) {
      GameMode.crowd => 'Запомни этого человека',
      GameMode.multi => 'Запомни ${_targets.length} лица',
      GameMode.memo => 'Запомни это лицо',
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (_targets.length == 1)
          SizedBox(
            width: 220,
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _faceImage(_targets.first),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _targets
                .map((t) => SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _faceImage(t),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  String _pickPrompt() {
    switch (widget.mode) {
      case GameMode.memo:
        return 'Кто это был?';
      case GameMode.multi:
        final left =
            _targets.where((t) => !_found.contains(t.id)).length;
        return 'Найди всех — осталось: $left';
      case GameMode.crowd:
        return 'Где он?';
    }
  }

  Widget _pickGrid() {
    final n = _options.length;
    final cols = n >= 16 ? 5 : (n >= 9 ? 4 : 3);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _pickPrompt(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _options.map((f) {
              final ok = _found.contains(f.id);
              final bad = _wrong.contains(f.id);
              return GestureDetector(
                onTap: () => _onCellTap(f),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ok
                          ? Colors.green
                          : bad
                              ? Colors.red
                              : Theme.of(context).dividerColor,
                      width: (ok || bad) ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _faceImage(f),
                      if (ok)
                        Container(
                          color: Colors.green.withOpacity(0.15),
                          child: const Icon(Icons.check_circle,
                              color: Colors.green),
                        ),
                      if (bad)
                        Container(
                          color: Colors.red.withOpacity(0.15),
                          child:
                              const Icon(Icons.cancel, color: Colors.red),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _gameOver() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Игра окончена',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('$_score очков · уровень $_level · ${_spec.label}'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              setState(() {
                _level = 1;
                _score = 0;
                _lives = 3;
                _streak = 0;
              });
              _startRound();
            },
            child: const Text('Играть снова'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('В меню'),
          ),
        ],
      ),
    );
  }
}
