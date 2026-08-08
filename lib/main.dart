import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'features/home/home_screen.dart';

// Firebase.initializeApp() は firebase_options.dart 生成後（flutter-firebase-setup
// スキルでの本設定完了後）に main() へ追加する。プレースホルダーのまま呼ぶと起動時に
// 例外になるため、Firebase未設定の間はコメントアウトのまま維持すること。
void main() {
  runApp(const ProviderScope(child: TetsudoTeikokuApp()));
}

class TetsudoTeikokuApp extends StatelessWidget {
  const TetsudoTeikokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '鉄道帝国',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
