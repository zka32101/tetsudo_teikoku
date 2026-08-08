import 'package:flutter/material.dart';
import '../data/models/game_event.dart';

/// ホーム画面上部に表示するイベント通知バナー。
class EventBanner extends StatelessWidget {
  final List<GameEvent> events;
  final void Function(GameEvent event)? onTap;

  const EventBanner({super.key, required this.events, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final event = events.first;

    return InkWell(
      key: const Key('event_banner'),
      onTap: onTap == null ? null : () => onTap!(event),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.description,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
