import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../data/models/station.dart';
import '../../providers/station_providers.dart';

/// 町を作品化＆SNS共有画面（設計書§5-11）。町のカード化とSNS共有ボタン。
class TownShareScreen extends ConsumerWidget {
  final String stationID;

  const TownShareScreen({super.key, required this.stationID});

  Future<void> _share(BuildContext context, Station station) async {
    final text =
        '「${station.name}」駅を育てています！\n'
        'Lv.${station.level} ・ 月間収益 ¥${station.revenue} ・ 魅力度 ${station.appealScore}\n'
        '#鉄道帝国';
    try {
      await Share.share(text);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('シェアに失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(stationDetailProvider(stationID));

    return Scaffold(
      appBar: AppBar(title: const Text('町をシェア')),
      body: stationAsync.when(
        data: (station) {
          if (station == null) {
            return const Center(child: Text('駅が見つかりません'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(child: _TownCard(station: station)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const Key('share_button'),
                  onPressed: () => _share(context, station),
                  icon: const Icon(Icons.share),
                  label: const Text('SNSでシェアする'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みエラー: $error')),
      ),
    );
  }
}

class _TownCard extends StatelessWidget {
  final Station station;

  const _TownCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('town_card'),
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient(
          station.developmentType,
          isDark: isDark,
        ),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(station.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('Lv.${station.level}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(label: '月間収益', value: '¥${station.revenue}'),
              _StatColumn(label: '魅力度', value: '${station.appealScore}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
