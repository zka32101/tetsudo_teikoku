import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../core/game_logic/compatibility_calculator.dart';
import '../../data/models/index.dart';
import '../../providers/service_providers.dart';
import '../../providers/station_providers.dart';

/// 駅員プロフィール画面（設計書§5-3）。
/// レア度・ステータス表示、他駅員との相性マトリックス、チーム編成UI。
class StaffProfileScreen extends ConsumerStatefulWidget {
  final String stationID;
  final String staffID;

  const StaffProfileScreen({
    super.key,
    required this.stationID,
    required this.staffID,
  });

  @override
  ConsumerState<StaffProfileScreen> createState() =>
      _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  String? _selectedPartnerID;
  bool _forming = false;

  /// 選択中の相手を安全に探す。リストが更新されて相手が消えていればnullを返す
  /// （firstWhereをorElseなしで使うとStateErrorで落ちるため）。
  StationStaff? _selectedPartner(List<StationStaff> others) {
    final id = _selectedPartnerID;
    if (id == null) return null;
    final matches = others.where((s) => s.staffID == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _formTeam(StationStaff self, StationStaff partner) async {
    if (_forming) return;
    setState(() => _forming = true);

    try {
      final bonus = calculateCompatibilityBonus(self, partner);
      final efficiency = calculateTotalEfficiency(self, partner);

      final firestore = ref.read(firestoreServiceProvider);
      // ペアの並び順に依らず同じIDになるよう正規化する（順序依存だと同じペアで
      // 重複ドキュメントができてしまうため）。
      final pairIds = [self.staffID, partner.staffID]..sort();
      await firestore.createTeamFormation(
        TeamFormation(
          teamID: pairIds.join('_'),
          stationID: widget.stationID,
          staffID1: self.staffID,
          staffID2: partner.staffID,
          compatibilityBonus: bonus,
          totalEfficiency: efficiency,
        ),
      );
      await ref
          .read(analyticsServiceProvider)
          .logTeamFormed(stationID: widget.stationID, compatibilityBonus: bonus)
          .catchError((_) {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('チーム編成に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _forming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByStationProvider(widget.stationID));

    return Scaffold(
      appBar: AppBar(title: const Text('駅員プロフィール')),
      body: staffAsync.when(
        data: (staffList) {
          final selfMatches = staffList.where(
            (s) => s.staffID == widget.staffID,
          );
          final self = selfMatches.isEmpty ? null : selfMatches.first;
          if (self == null) {
            return const Center(child: Text('駅員が見つかりません'));
          }
          final others = staffList
              .where((s) => s.staffID != widget.staffID)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StaffStatsCard(staff: self),
              const SizedBox(height: 24),
              Text('相性マトリックス', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (others.isEmpty)
                const Text('他に駅員がいません')
              else
                ...others.map(
                  (other) => _CompatibilityTile(
                    key: Key('compatibility_tile_${other.staffID}'),
                    self: self,
                    other: other,
                    selected: _selectedPartnerID == other.staffID,
                    onTap: () =>
                        setState(() => _selectedPartnerID = other.staffID),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('form_team_button'),
                onPressed: _forming || _selectedPartner(others) == null
                    ? null
                    : () => _formTeam(self, _selectedPartner(others)!),
                child: _forming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('チームを組む'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みエラー: $error')),
      ),
    );
  }
}

class _StaffStatsCard extends StatelessWidget {
  final StationStaff staff;

  const _StaffStatsCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(staff.name, style: Theme.of(context).textTheme.titleLarge),
                Chip(label: Text(staffRarityToString(staff.rarity))),
              ],
            ),
            Text('Lv.${staff.level} ・ EXP ${staff.exp}'),
            const SizedBox(height: 8),
            _StatBar(label: '接客', value: staff.stats.hospitality),
            _StatBar(label: '効率', value: staff.stats.efficiency),
            _StatBar(label: '優しさ', value: staff.stats.kindness),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;

  const _StatBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(value: (value / 100).clamp(0, 1)),
          ),
          const SizedBox(width: 8),
          Text('$value'),
        ],
      ),
    );
  }
}

class _CompatibilityTile extends StatelessWidget {
  final StationStaff self;
  final StationStaff other;
  final bool selected;
  final VoidCallback onTap;

  const _CompatibilityTile({
    super.key,
    required this.self,
    required this.other,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bonus = calculateCompatibilityBonus(self, other);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(other.name),
        subtitle: Text('相性ボーナス x${bonus.toStringAsFixed(2)}'),
        trailing: selected ? const Icon(Icons.check_circle) : null,
      ),
    );
  }
}
