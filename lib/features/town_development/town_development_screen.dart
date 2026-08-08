import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../core/game_logic/town_bonus_calculator.dart';
import '../../data/models/index.dart';
import '../../providers/service_providers.dart';

/// 町の発展分岐選択（設計書§5-4）。温泉/商業/観光の3択とプレビュー、確定ボタン。
class TownDevelopmentScreen extends ConsumerStatefulWidget {
  final String stationID;

  const TownDevelopmentScreen({super.key, required this.stationID});

  @override
  ConsumerState<TownDevelopmentScreen> createState() =>
      _TownDevelopmentScreenState();
}

class _TownDevelopmentScreenState
    extends ConsumerState<TownDevelopmentScreen> {
  DevelopmentType? _selected;
  bool _submitting = false;

  static const _choices = [
    DevelopmentType.onsen,
    DevelopmentType.shogyo,
    DevelopmentType.kanko,
  ];

  static const _labels = {
    DevelopmentType.onsen: '温泉',
    DevelopmentType.shogyo: '商業',
    DevelopmentType.kanko: '観光',
  };

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null || _submitting) return;

    setState(() => _submitting = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.updateStationDevelopment(widget.stationID, selected);
      await firestore.createTownDevelopment(
        TownDevelopment(
          townID: '${widget.stationID}_town',
          stationID: widget.stationID,
          developmentType: selected,
          level: 1,
          aesthetics: 50,
          liveliness: 50,
          visualAssetID: null,
          selectedAt: DateTime.now(),
        ),
      );
      await ref
          .read(analyticsServiceProvider)
          .logTownDeveloped(
            stationID: widget.stationID,
            developmentType: developmentTypeToString(selected),
          )
          .catchError((_) {});

      if (mounted) Navigator.of(context).pop(selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('発展に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('町の発展を選ぼう')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'どの方向に町を発展させますか？',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _choices
                    .map((type) => _DevelopmentChoiceCard(
                          key: Key('development_choice_${type.name}'),
                          type: type,
                          label: _labels[type]!,
                          selected: _selected == type,
                          onTap: () => setState(() => _selected = type),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('development_confirm_button'),
              onPressed: _selected == null || _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('この方向で発展させる'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentChoiceCard extends StatelessWidget {
  final DevelopmentType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DevelopmentChoiceCard({
    super.key,
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forDevelopment(type);
    final bonus = calculateTownBonusFromDevelopment(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(
          color: selected ? accent : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimens.minTapTarget),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: accent, radius: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '収益倍率 x${bonus.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
