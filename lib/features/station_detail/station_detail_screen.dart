import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../core/game_logic/revenue_calculator.dart';
import '../../core/game_logic/town_growth_calculator.dart';
import '../../data/models/station.dart';
import '../../data/models/station_staff.dart';
import '../../data/models/town_development.dart';
import '../../providers/service_providers.dart';
import '../../providers/station_providers.dart';
import '../paywall/paywall_screen.dart';
import '../rush_hour/rush_hour_screen.dart';
import '../share/town_share_screen.dart';
import '../staff_profile/staff_profile_screen.dart';
import '../timetable/timetable_design_screen.dart';
import '../town_development/town_development_screen.dart';

/// 駅前景観・駅員配置エリア・施設管理・収益表示（設計書§5-2）。
class StationDetailScreen extends ConsumerWidget {
  final String stationID;

  const StationDetailScreen({super.key, required this.stationID});

  Future<void> _openStaffProfile(BuildContext context, String staffID) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            StaffProfileScreen(stationID: stationID, staffID: staffID),
      ),
    );
  }

  Future<void> _openTownDevelopment(BuildContext context, WidgetRef ref) async {
    final selected = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TownDevelopmentScreen(stationID: stationID),
      ),
    );
    if (selected != null) {
      // 発展タイプが変わったので、駅情報と発展状況を再取得して景観に反映する。
      ref.invalidate(stationDetailProvider(stationID));
      ref.invalidate(townDevelopmentProvider(stationID));
    }
    // Aha Moment直後にペイウォールを表示する（設計書「ペイウォール位置：Aha直後」）。
    if (selected != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  Future<void> _openTimetable(BuildContext context, WidgetRef ref, String railroadID) async {
    final userID = await ref.read(currentUserIdProvider.future);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TimetableDesignScreen(userID: userID, railroadID: railroadID),
      ),
    );
  }

  void _openRushHour(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RushHourScreen(stationID: stationID)),
    );
  }

  void _openShare(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TownShareScreen(stationID: stationID)),
    );
  }

  /// Aha Moment: 駅員配置→月間収益計算（設計書§6 POST /station/{id}/develop相当）。
  /// Cloud Functions未実装のため、計算自体はクライアント側のローカルスタブで行う。
  Future<void> _calculateRevenue(
    BuildContext context,
    WidgetRef ref,
    Station station,
    List<StationStaff> staffList,
  ) async {
    final revenue = calculateMonthlyRevenue(
      staff: staffList,
      developmentType: station.developmentType,
      passengersPerDay: station.passengersPerDay,
    );

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        key: const Key('revenue_result_dialog'),
        title: const Text('今月の収益'),
        content: Text('¥$revenue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    await ref
        .read(analyticsServiceProvider)
        .logAhaMomentReached(stationID: stationID, revenue: revenue)
        .catchError((_) {});

    // 発展済みの町なら、収益に応じて美しさ・賑わい・レベルを伸ばす
    // （成長カードが実際に育つようにするためのローカルスタブ処理）。
    // Firebase未設定の間は失敗してもダイアログ表示自体は成功させたいため、
    // ここだけ独立してエラーを握りつぶす。
    if (station.developmentType != DevelopmentType.none) {
      try {
        final current = await ref.read(
          townDevelopmentProvider(stationID).future,
        );
        if (current != null) {
          final grown = applyRevenueGrowth(current, revenue);
          await ref.read(firestoreServiceProvider).createTownDevelopment(grown);
          ref.invalidate(townDevelopmentProvider(stationID));
        }
      } catch (_) {
        // Firebase未設定時の失敗は無視する。
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(stationDetailProvider(stationID));
    final staffAsync = ref.watch(staffByStationProvider(stationID));
    final townDevelopmentAsync = ref.watch(townDevelopmentProvider(stationID));

    return Scaffold(
      body: stationAsync.when(
        data: (station) {
          if (station == null) {
            return const Center(child: Text('駅が見つかりません'));
          }
          return _StationDetailBody(
            station: station,
            staffAsync: staffAsync,
            townDevelopmentAsync: townDevelopmentAsync,
            onStaffTap: (staffID) => _openStaffProfile(context, staffID),
            onDevelopTown: () => _openTownDevelopment(context, ref),
            onEditTimetable: () =>
                _openTimetable(context, ref, station.railroadID),
            onRushHour: () => _openRushHour(context),
            onShare: () => _openShare(context),
            onCalculateRevenue: (staffList) =>
                _calculateRevenue(context, ref, station, staffList),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みエラー: $error')),
      ),
    );
  }
}

class _StationDetailBody extends StatelessWidget {
  final Station station;
  final AsyncValue<List<StationStaff>> staffAsync;
  final AsyncValue<TownDevelopment?> townDevelopmentAsync;
  final void Function(String staffID) onStaffTap;
  final VoidCallback onDevelopTown;
  final VoidCallback onEditTimetable;
  final VoidCallback onRushHour;
  final VoidCallback onShare;
  final void Function(List<StationStaff> staffList) onCalculateRevenue;

  const _StationDetailBody({
    required this.station,
    required this.staffAsync,
    required this.townDevelopmentAsync,
    required this.onStaffTap,
    required this.onDevelopTown,
    required this.onEditTimetable,
    required this.onRushHour,
    required this.onShare,
    required this.onCalculateRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('station_townscape'),
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient(
          station.developmentType,
          isDark: isDark,
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(station.name),
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RevenueCard(station: station),
                  if (station.developmentType != DevelopmentType.none) ...[
                    const SizedBox(height: 16),
                    townDevelopmentAsync.when(
                      data: (development) => development == null
                          ? const SizedBox.shrink()
                          : _TownGrowthCard(
                              developmentType: station.developmentType,
                              development: development,
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => const SizedBox.shrink(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('駅員配置', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  staffAsync.when(
                    data: (staffList) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StaffAssignmentArea(
                          staffList: staffList,
                          onStaffTap: onStaffTap,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('calculate_revenue_button'),
                          onPressed: () => onCalculateRevenue(staffList),
                          icon: const Icon(Icons.calculate),
                          label: const Text('収益を計算する'),
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('駅員読み込みエラー: $error'),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (station.developmentType == DevelopmentType.none)
                        ElevatedButton.icon(
                          key: const Key('go_develop_town_button'),
                          onPressed: onDevelopTown,
                          icon: const Icon(Icons.park),
                          label: const Text('町を発展させる'),
                        ),
                      OutlinedButton.icon(
                        key: const Key('go_timetable_button'),
                        onPressed: onEditTimetable,
                        icon: const Icon(Icons.schedule),
                        label: const Text('時刻表デザイン'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('go_rush_hour_button'),
                        onPressed: onRushHour,
                        icon: const Icon(Icons.directions_run),
                        label: const Text('ラッシュアワー'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('go_share_button'),
                        onPressed: onShare,
                        icon: const Icon(Icons.share),
                        label: const Text('町をシェア'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final Station station;

  const _RevenueCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('月間収益', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '¥${station.revenue}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('魅力度', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${station.appealScore}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 町の発展状況（レベル・美しさ・賑わい）を可視化するカード。
class _TownGrowthCard extends StatelessWidget {
  final DevelopmentType developmentType;
  final TownDevelopment development;

  const _TownGrowthCard({
    required this.developmentType,
    required this.development,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forDevelopment(developmentType);
    final icon = developmentTypeIcon(developmentType);
    final iconCount = development.level.clamp(1, 5);

    return Card(
      key: const Key('town_growth_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('町の発展度', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Text('Lv.${development.level}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                iconCount,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(icon, color: accent, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _GrowthStat(label: '美しさ', value: development.aesthetics, color: accent),
            const SizedBox(height: 4),
            _GrowthStat(label: '賑わい', value: development.liveliness, color: accent),
          ],
        ),
      ),
    );
  }
}

class _GrowthStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _GrowthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value'),
      ],
    );
  }
}

class _StaffAssignmentArea extends StatelessWidget {
  final List<StationStaff> staffList;
  final void Function(String staffID) onStaffTap;

  const _StaffAssignmentArea({required this.staffList, required this.onStaffTap});

  @override
  Widget build(BuildContext context) {
    if (staffList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('まだ駅員が配置されていません'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: staffList
          .map(
            (staff) => ActionChip(
              key: Key('staff_chip_${staff.staffID}'),
              avatar: const Icon(Icons.person, size: 18),
              label: Text('${staff.name} (${staffRarityToString(staff.rarity)})'),
              onPressed: () => onStaffTap(staff.staffID),
            ),
          )
          .toList(),
    );
  }
}
