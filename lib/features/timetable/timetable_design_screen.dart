import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game_logic/timetable_efficiency_calculator.dart';
import '../../data/models/index.dart';
import '../../providers/service_providers.dart';

/// 時刻表デザイン（設計書§5-10）。列車を追加してダイヤを組み、
/// 効率スコアをリアルタイムに表示する。
class TimetableDesignScreen extends ConsumerStatefulWidget {
  final String userID;
  final String railroadID;

  const TimetableDesignScreen({
    super.key,
    required this.userID,
    required this.railroadID,
  });

  @override
  ConsumerState<TimetableDesignScreen> createState() =>
      _TimetableDesignScreenState();
}

class _TimetableDesignScreenState
    extends ConsumerState<TimetableDesignScreen> {
  final List<TrainSchedule> _trains = [];
  final _startController = TextEditingController(text: '08:00');
  final _endController = TextEditingController(text: '08:30');
  final _stopsController = TextEditingController();
  bool _saving = false;
  // 削除後の再追加でIDが衝突しないよう、リスト長ではなく単調増加カウンタを使う。
  int _nextTrainNumber = 1;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _stopsController.dispose();
    super.dispose();
  }

  double get _efficiencyScore => calculateEfficiencyScore(
    TimetableDesign(
      timetableID: '',
      userID: widget.userID,
      railroadID: widget.railroadID,
      trains: _trains,
      efficiencyScore: 0,
      createdAt: DateTime.now(),
    ),
  );

  void _addTrain() {
    final stops = _stopsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (_startController.text.isEmpty || _endController.text.isEmpty) return;

    setState(() {
      _trains.add(
        TrainSchedule(
          trainID: 'train_${_nextTrainNumber++}',
          startTime: _startController.text,
          endTime: _endController.text,
          stops: stops,
        ),
      );
      _stopsController.clear();
    });
  }

  void _removeTrain(int index) {
    setState(() => _trains.removeAt(index));
  }

  Future<void> _save() async {
    if (_trains.isEmpty || _saving) return;
    setState(() => _saving = true);

    try {
      final score = _efficiencyScore;
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.saveTimetableDesign(
        TimetableDesign(
          timetableID: '${widget.userID}_${widget.railroadID}_${DateTime.now().millisecondsSinceEpoch}',
          userID: widget.userID,
          railroadID: widget.railroadID,
          trains: _trains,
          efficiencyScore: score,
          createdAt: DateTime.now(),
        ),
      );
      await ref
          .read(analyticsServiceProvider)
          .logTimetableDesigned(
            railroadID: widget.railroadID,
            efficiencyScore: score,
          )
          .catchError((_) {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('時刻表デザイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('効率スコア', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      key: const Key('efficiency_score'),
                      _efficiencyScore.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('start_time_field'),
                    controller: _startController,
                    decoration: const InputDecoration(labelText: '発車 (HH:mm)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('end_time_field'),
                    controller: _endController,
                    decoration: const InputDecoration(labelText: '到着 (HH:mm)'),
                  ),
                ),
              ],
            ),
            TextField(
              key: const Key('stops_field'),
              controller: _stopsController,
              decoration: const InputDecoration(labelText: '停車駅 (カンマ区切り)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('add_train_button'),
              onPressed: _addTrain,
              child: const Text('列車を追加'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                key: const Key('train_list'),
                itemCount: _trains.length,
                itemBuilder: (context, index) {
                  final train = _trains[index];
                  return ListTile(
                    key: Key('train_tile_${train.trainID}'),
                    title: Text('${train.startTime} → ${train.endTime}'),
                    subtitle: Text('停車: ${train.stops.join(", ")}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeTrain(index),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              key: const Key('save_timetable_button'),
              onPressed: _trains.isEmpty || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存する'),
            ),
          ],
        ),
      ),
    );
  }
}
