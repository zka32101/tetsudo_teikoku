import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../providers/selection_providers.dart';
import '../../providers/station_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/event_banner.dart';
import '../../widgets/station_list_card.dart';
import '../event/event_detail_screen.dart';
import '../railroad_map/railroad_map_screen.dart';
import '../ranking/ranking_screen.dart';
import '../station_detail/station_detail_screen.dart';

/// 駅マップ表示・駅一覧・資金/レベル表示・イベント通知バナー（設計書§5-1）。
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Firebase未初期化(Phase 2完了まで)の間は例外を握りつぶす。
    ref.read(analyticsServiceProvider).logHomeViewed().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final railroadId = ref.watch(selectedRailroadIdProvider);
    final stationsAsync = ref.watch(stationsByRailroadProvider(railroadId));
    final eventsAsync = ref.watch(activeEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('鉄道帝国'),
        actions: [
          IconButton(
            key: const Key('open_railroad_map_button'),
            icon: const Icon(Icons.map),
            tooltip: '路線マップ',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RailroadMapScreen(railroadID: railroadId),
              ),
            ),
          ),
          IconButton(
            key: const Key('open_ranking_button'),
            icon: const Icon(Icons.emoji_events),
            tooltip: '魅力度ランキング',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RankingScreen()),
            ),
          ),
          userProfileAsync.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  profile == null
                      ? '¥0 ・ Lv.1'
                      : '¥${profile.currentMoney} ・ Lv.${profile.level}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          eventsAsync.when(
            data: (events) => EventBanner(
              events: events,
              onTap: (event) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Expanded(
            child: stationsAsync.when(
              data: (stations) {
                if (stations.isEmpty) {
                  return const Center(child: Text('まだ駅がありません'));
                }
                return ListView.builder(
                  key: const Key('station_list'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return StationListCard(
                      station: station,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StationDetailScreen(stationID: station.stationID),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('読み込みエラー: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
