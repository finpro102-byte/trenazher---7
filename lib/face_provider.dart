import 'dart:math';
import 'package:flutter/material.dart';

/// Лицо в игре. Уникально идентифицируется [id].
class Face {
  const Face({required this.id, required this.image});
  final String id;
  final ImageProvider image;
}

/// Источник лиц для игровых раундов.
abstract class FaceProvider {
  Future<Face> nextFace();

  Future<List<Face>> nextFaces(int n) async {
    final out = <Face>[];
    for (var i = 0; i < n; i++) {
      out.add(await nextFace());
    }
    return out;
  }
}

/// Портреты из публичной галереи Random User.
/// Требуется интернет. Используем разные фиксированные URL, чтобы изображения
/// стабильно загружались и кэшировались между раундами.
class GanFaceProvider extends FaceProvider {
  GanFaceProvider();

  final Random _rng = Random();
  final Set<String> _recent = <String>{};
  int _seq = 0;

  @override
  Future<Face> nextFace() async {
    _seq++;
    // Random User предоставляет отдельные портреты в каталогах men и women.
    // Чередование пола и случайный номер даёт разнообразные лица.
    final gender = _rng.nextBool() ? 'men' : 'women';
    final number = _rng.nextInt(99);
    final id = 'portrait_${gender}_$number';
    // Сохраняем уникальность лиц внутри одного раунда насколько это возможно.
    // Если URL уже использовался недавно, выбираем другой.
    var chosenGender = gender;
    var chosenNumber = number;
    var chosenId = id;
    for (var i = 0; i < 30 && _recent.contains(chosenId); i++) {
      chosenGender = _rng.nextBool() ? 'men' : 'women';
      chosenNumber = _rng.nextInt(99);
      chosenId = 'portrait_${chosenGender}_$chosenNumber';
    }
    _recent.add(chosenId);
    if (_recent.length > 150) _recent.clear();

    return Face(
      id: '${chosenId}_$_seq',
      image: NetworkImage(
        'https://randomuser.me/api/portraits/$chosenGender/$chosenNumber.jpg',
      ),
    );
  }
}

/// Офлайн-источник, если позже добавите собственные файлы
/// assets/faces/face_0001.jpg, assets/faces/face_0002.jpg и т.д.
class AssetFaceProvider extends FaceProvider {
  AssetFaceProvider({required this.count}) : assert(count > 0);

  final int count;
  final _rng = Random();
  final _used = <String>{};

  @override
  Future<Face> nextFace() async {
    var guard = 0;
    String id;
    do {
      id = 'face_${(1 + _rng.nextInt(count)).toString().padLeft(4, '0')}';
    } while (_used.contains(id) && guard++ < count * 2);
    _used.add(id);
    if (_used.length > count * 0.9) _used.clear();
    return Face(id: id, image: AssetImage('assets/faces/$id.jpg'));
  }
}
