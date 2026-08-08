import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_event.dart';
import '../../providers/service_providers.dart';

/// 四季イベント/予想外イベント画面（設計書§5-8）。
/// イベント説明・ミッション内容・報酬プレビュー・参加ボタン。
class EventDetailScreen extends ConsumerStatefulWidget {
  final GameEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _joining = false;
  bool _joined = false;

  Future<void> _join() async {
    if (_joining || _joined) return;
    setState(() => _joining = true);

    await ref
        .read(analyticsServiceProvider)
        .logEventCompleted(eventID: widget.event.eventID)
        .catchError((_) {});

    if (mounted) {
      setState(() {
        _joining = false;
        _joined = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(title: const Text('イベント')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(event.description, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '開催期間: ${_formatDate(event.startTime)} 〜 ${_formatDate(event.endTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard),
                    const SizedBox(width: 12),
                    Text(
                      '報酬: ${event.reward.rewardType} x${event.reward.amount}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              key: const Key('join_event_button'),
              onPressed: _joining || _joined ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_joined ? '参加済み' : 'イベントに参加する'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month}/${date.day}';
}
