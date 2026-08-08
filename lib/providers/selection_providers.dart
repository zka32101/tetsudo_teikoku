import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ホーム画面で表示中の路線ID。v1.0は5路線を切り替えて管理する想定。
/// 既定値は東海道線のプレースホルダーID。路線選択UIは今後実装。
final selectedRailroadIdProvider = StateProvider<String>((ref) => 'tokaido_line');
