import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../data/models/station.dart';

/// ホーム画面の駅一覧に表示する1件分のカード。
class StationListCard extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;

  const StationListCard({super.key, required this.station, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forDevelopment(station.developmentType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppDimens.minTapTarget),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.${station.level} ・ 乗客${station.passengersPerDay}人/日',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '¥${station.revenue}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
