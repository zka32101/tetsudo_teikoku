import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

import '../../core/game_logic/rush_hour_score_calculator.dart';

enum PassengerType { normal, vip, obstacle }

/// ラッシュアワーミニゲーム（設計書§5-5）。乗客が上から降ってきて、
/// タップでさばく。VIP乗客は高得点、邪魔な乗客はタップすると減点(見送るのが正解)。
/// ミス無く連続で正解し続けるとコンボボーナスが積み上がる。
/// 時間経過で乗客の出現間隔が短くなり難易度が上がる。
class RushHourGame extends FlameGame {
  static const double gameDurationSeconds = 30;
  static const double _baseSpawnIntervalSeconds = 0.8;
  static const double _minSpawnIntervalSeconds = 0.3;

  final void Function(int score) onComplete;

  int passengersHandled = 0;
  int passengersMissed = 0;
  int vipHandled = 0;
  int vipMissed = 0;
  int obstaclesTapped = 0;
  int currentCombo = 0;
  int longestCombo = 0;

  int _passengersSpawned = 0;
  double _elapsed = 0;
  double _spawnTimer = 0;
  bool _finished = false;
  final Random _random = Random();
  late final TextComponent _comboText;

  RushHourGame({required this.onComplete});

  @override
  Color backgroundColor() => const Color(0xFF0066CC);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _comboText = TextComponent(
      text: '',
      position: Vector2(12, 12),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_comboText);
  }

  @override
  void update(double dt) {
    if (_finished) return;
    super.update(dt);

    _comboText.text = currentCombo >= 2 ? 'コンボ x$currentCombo' : '';

    _elapsed += dt;
    _spawnTimer += dt;
    final spawnInterval = calculateSpawnInterval(
      elapsedSeconds: _elapsed,
      baseIntervalSeconds: _baseSpawnIntervalSeconds,
      minIntervalSeconds: _minSpawnIntervalSeconds,
    );
    if (_spawnTimer >= spawnInterval) {
      _spawnTimer = 0;
      _spawnPassenger();
    }

    if (_elapsed >= gameDurationSeconds) {
      _finish();
    }
  }

  PassengerType _pickPassengerType() {
    final roll = _random.nextDouble();
    if (roll < 0.15) return PassengerType.vip;
    if (roll < 0.30) return PassengerType.obstacle;
    return PassengerType.normal;
  }

  void _spawnPassenger() {
    final laneCount = 5;
    final lane = _passengersSpawned % laneCount;
    _passengersSpawned++;
    final laneWidth = size.x / laneCount;
    final type = _pickPassengerType();
    add(
      Passenger(
        type: type,
        startX: laneWidth * lane + laneWidth / 2,
        onMissed: () => _registerMissed(type),
        onHandled: () => _registerHandled(type),
      ),
    );
  }

  void _registerHandled(PassengerType type) {
    switch (type) {
      case PassengerType.normal:
        passengersHandled++;
        _registerComboSuccess();
      case PassengerType.vip:
        vipHandled++;
        _registerComboSuccess();
      case PassengerType.obstacle:
        obstaclesTapped++;
        _registerComboBreak();
    }
  }

  void _registerMissed(PassengerType type) {
    switch (type) {
      case PassengerType.normal:
        passengersMissed++;
        _registerComboBreak();
      case PassengerType.vip:
        vipMissed++;
        _registerComboBreak();
      case PassengerType.obstacle:
        // 邪魔な乗客を正しく見送れた（タップしなかった）ので、減点無しでコンボ継続。
        _registerComboSuccess();
    }
  }

  void _registerComboSuccess() {
    currentCombo++;
    if (currentCombo > longestCombo) longestCombo = currentCombo;
  }

  void _registerComboBreak() {
    currentCombo = 0;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    onComplete(
      calculateRushHourScore(
        passengersHandled: passengersHandled,
        passengersMissed: passengersMissed,
        vipHandled: vipHandled,
        vipMissed: vipMissed,
        obstaclesTapped: obstaclesTapped,
        longestCombo: longestCombo,
      ),
    );
  }
}

/// 画面を降ってくる乗客。タップすると「さばいた」扱いになり消える。
/// 画面外に落ちると「取りこぼし」扱いになる（邪魔な乗客は見送るのが正解）。
class Passenger extends PositionComponent
    with TapCallbacks, HasGameReference<RushHourGame> {
  static const double _speed = 90;
  static const double _size = 36;

  final PassengerType type;
  final void Function() onMissed;
  final void Function() onHandled;
  bool _resolved = false;

  Passenger({
    required this.type,
    required double startX,
    required this.onMissed,
    required this.onHandled,
  }) : super(
         position: Vector2(startX, 0),
         size: Vector2.all(_size),
         anchor: Anchor.center,
       );

  Color get _color {
    switch (type) {
      case PassengerType.normal:
        return const Color(0xFFFF9900);
      case PassengerType.vip:
        return const Color(0xFFFFD700);
      case PassengerType.obstacle:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_resolved) return;

    position.y += _speed * dt;
    if (position.y > game.size.y) {
      _resolved = true;
      onMissed();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _color;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_resolved) return;
    _resolved = true;
    onHandled();
    removeFromParent();
  }
}
