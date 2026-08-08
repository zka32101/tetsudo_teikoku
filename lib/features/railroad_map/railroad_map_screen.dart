import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../data/models/station.dart';
import '../../providers/station_providers.dart';
import '../station_detail/station_detail_screen.dart';

/// 路線マップ画面（設計書§5-7）。全体路線図と、駅ごとの簡易な発展履歴年表を表示する。
class RailroadMapScreen extends ConsumerWidget {
  final String railroadID;

  const RailroadMapScreen({super.key, required this.railroadID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationsByRailroadProvider(railroadID));

    return Scaffold(
      appBar: AppBar(title: const Text('路線マップ')),
      body: stationsAsync.when(
        data: (stations) {
          if (stations.isEmpty) {
            return const Center(child: Text('この路線にはまだ駅がありません'));
          }
          final history = [...stations]
            ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

          return ListView(
            key: const Key('railroad_map_list'),
            padding: const EdgeInsets.all(16),
            children: [
              Text('路線図', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...stations.map(
                (station) => _StationMapTile(
                  station: station,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          StationDetailScreen(stationID: station.stationID),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('沿線の歴史', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...history.map((station) => _HistoryTile(station: station)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みエラー: $error')),
      ),
    );
  }
}

class _StationMapTile extends StatelessWidget {
  final Station station;
  final VoidCallback onTap;

  const _StationMapTile({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forDevelopment(station.developmentType);
    return ListTile(
      key: Key('map_station_${station.stationID}'),
      leading: CircleAvatar(backgroundColor: accent, radius: 8),
      title: Text(station.name),
      subtitle: Text('Lv.${station.level}'),
      onTap: onTap,
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Station station;

  const _HistoryTile({required this.station});

  @override
  Widget build(BuildContext context) {
    final date = station.lastUpdated;
    return ListTile(
      key: Key('history_${station.stationID}'),
      leading: const Icon(Icons.history),
      title: Text('${station.name}駅がレベル${station.level}に到達'),
      subtitle: Text('${date.year}/${date.month}/${date.day}'),
    );
  }
}
