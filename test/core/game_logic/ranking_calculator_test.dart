import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/ranking_calculator.dart';

void main() {
  group('calculateRanking', () {
    test('ranks users by descending appeal score', () {
      final result = calculateRanking({'a': 100, 'b': 90, 'c': 80});
      expect(result.map((r) => r.userID).toList(), ['a', 'b', 'c']);
      expect(result.map((r) => r.rank).toList(), [1, 2, 3]);
    });

    test('ties share the same rank and skip the next position (1224)', () {
      final result = calculateRanking({'a': 100, 'b': 100, 'c': 90});
      final byUser = {for (final r in result) r.userID: r.rank};
      expect(byUser['a'], 1);
      expect(byUser['b'], 1);
      expect(byUser['c'], 3);
    });

    test('empty input returns empty ranking', () {
      expect(calculateRanking({}), isEmpty);
    });
  });
}
