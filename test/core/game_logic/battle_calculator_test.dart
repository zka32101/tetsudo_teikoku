import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/battle_calculator.dart';

void main() {
  group('calculateBattleResult', () {
    test('higher appeal score wins as challenger', () {
      final result = calculateBattleResult(
        challengerAppealScore: 100,
        defenderAppealScore: 50,
      );
      expect(result.challengerWon, isTrue);
    });

    test('lower appeal score loses as challenger', () {
      final result = calculateBattleResult(
        challengerAppealScore: 50,
        defenderAppealScore: 100,
      );
      expect(result.challengerWon, isFalse);
    });

    test('tie goes to the defender (home advantage)', () {
      final result = calculateBattleResult(
        challengerAppealScore: 80,
        defenderAppealScore: 80,
      );
      expect(result.challengerWon, isFalse);
    });

    test('winner reward exceeds loser reward', () {
      final result = calculateBattleResult(
        challengerAppealScore: 100,
        defenderAppealScore: 50,
      );
      expect(result.winnerReward, greaterThan(result.loserReward));
    });
  });
}
