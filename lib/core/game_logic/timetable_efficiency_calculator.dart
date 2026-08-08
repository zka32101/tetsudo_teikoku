import '../../data/models/timetable_design.dart';

int _parseTimeToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

double _average(List<num> values) {
  if (values.isEmpty) return 0;
  final sum = values.fold<double>(0, (acc, v) => acc + v);
  return sum / values.length;
}

double _standardDeviation(List<num> values) {
  if (values.length < 2) return 0;
  final avg = _average(values);
  final sumSquaredDiff = values.fold<double>(
    0,
    (acc, v) => acc + (v - avg) * (v - avg),
  );
  final variance = sumSquaredDiff / values.length;
  return variance <= 0 ? 0 : _sqrt(variance);
}

double _sqrt(double value) {
  if (value == 0) return 0;
  double guess = value;
  for (var i = 0; i < 20; i++) {
    guess = 0.5 * (guess + value / guess);
  }
  return guess;
}

/// 時刻表の効率スコア(0-100)を算出する。
/// - 発車間隔の均等さ（等間隔ダイヤほど高評価）
/// - 1本あたりの停車駅数（カバレッジ）
/// の2軸を加重平均する。
double calculateEfficiencyScore(TimetableDesign timetable) {
  final trains = timetable.trains;
  if (trains.isEmpty) return 0;

  final startMinutes = trains
      .map((t) => _parseTimeToMinutes(t.startTime))
      .toList()
    ..sort();

  double regularityScore = 100;
  if (startMinutes.length == 2) {
    // 間隔が1つしかないと「均等さ」自体を判定できないため、満点にはしない。
    regularityScore = 70;
  } else if (startMinutes.length >= 3) {
    final gaps = <int>[];
    for (var i = 1; i < startMinutes.length; i++) {
      gaps.add(startMinutes[i] - startMinutes[i - 1]);
    }
    final gapStdDev = _standardDeviation(gaps);
    // 標準偏差 0分(完全等間隔) → 100点、60分以上のばらつきで0点。
    regularityScore = (100 - (gapStdDev / 60 * 100)).clamp(0, 100);
  }

  final avgStops = _average(trains.map((t) => t.stops.length).toList());
  // 1本あたり平均10駅停車で満点、それ以上は頭打ち。
  final coverageScore = (avgStops / 10 * 100).clamp(0, 100);

  return (regularityScore * 0.6 + coverageScore * 0.4).clamp(0, 100);
}
