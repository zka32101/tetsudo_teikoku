import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/station.dart';

/// 設計書 §8 UI/UXクオリティ基準のカラーパレット。
class AppColors {
  static const railwayBlue = Color(0xFF0066CC);
  static const onsenOrange = Color(0xFFFF9900);
  static const shogyoGreen = Color(0xFF00AA00);
  static const kankoPink = Color(0xFFFF66CC);

  static Color forDevelopment(DevelopmentType type) {
    switch (type) {
      case DevelopmentType.onsen:
        return onsenOrange;
      case DevelopmentType.shogyo:
        return shogyoGreen;
      case DevelopmentType.kanko:
        return kankoPink;
      case DevelopmentType.none:
        return railwayBlue;
    }
  }
}

/// 発展タイプごとの象徴アイコン（景観カード・発展分岐選択で共用）。
IconData developmentTypeIcon(DevelopmentType type) {
  switch (type) {
    case DevelopmentType.onsen:
      return Icons.hot_tub;
    case DevelopmentType.shogyo:
      return Icons.storefront;
    case DevelopmentType.kanko:
      return Icons.landscape;
    case DevelopmentType.none:
      return Icons.train;
  }
}

/// 44pt タップターゲット・角丸・影付きボタンの共通寸法。
class AppDimens {
  static const minTapTarget = 44.0;
  static const cardRadius = 16.0;
  static const buttonRadius = 24.0;
}

class AppTheme {
  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // ダークモードは彩度を下げて視認性を維持する(設計書§8)。
    final seed = isDark
        ? AppColors.railwayBlue.withValues(alpha: 0.85)
        : AppColors.railwayBlue;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final textTheme = GoogleFonts.mPlusRounded1cTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppDimens.minTapTarget,
            AppDimens.minTapTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.buttonRadius),
          ),
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        ),
      ),
    );
  }

  /// 白無地NGのため、画面背景は駅の発展タイプに応じたグラデーションを既定にする。
  static LinearGradient backgroundGradient(
    DevelopmentType type, {
    required bool isDark,
  }) {
    final base = AppColors.forDevelopment(type);
    final start = isDark ? base.withValues(alpha: 0.35) : base.withValues(alpha: 0.25);
    final end = isDark ? const Color(0xFF121212) : Colors.white;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [start, end],
    );
  }
}
