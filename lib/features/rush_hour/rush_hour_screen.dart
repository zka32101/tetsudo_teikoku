import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import 'rush_hour_game.dart';

/// ラッシュアワーミニゲーム画面。GameWidgetでFlameゲームをホストし、
/// 終了時にスコアを表示してrush_hour_completedを計測する。
class RushHourScreen extends ConsumerStatefulWidget {
  final String stationID;

  const RushHourScreen({super.key, required this.stationID});

  @override
  ConsumerState<RushHourScreen> createState() => _RushHourScreenState();
}

class _RushHourScreenState extends ConsumerState<RushHourScreen> {
  late final RushHourGame _game;
  int? _finalScore;

  @override
  void initState() {
    super.initState();
    _game = RushHourGame(onComplete: _onGameComplete);
  }

  void _onGameComplete(int score) {
    if (!mounted) return;
    setState(() => _finalScore = score);
    ref
        .read(analyticsServiceProvider)
        .logRushHourCompleted(stationID: widget.stationID, score: score)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ラッシュアワー')),
      body: Stack(
        children: [
          GameWidget(key: const Key('rush_hour_game_widget'), game: _game),
          if (_finalScore != null)
            Center(
              child: Card(
                key: const Key('rush_hour_result_card'),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'スコア $_finalScore',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_finalScore),
                        child: const Text('終了'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
