import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/rush_hour_score_calculator.dart';

void main() {
  group('calculateRushHourScore', () {
    test('rewards handled passengers', () {
      final score = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 0,
      );
      expect(score, 10 * 100);
    });

    test('penalizes missed passengers', () {
      final withMiss = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 3,
      );
      final withoutMiss = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 0,
      );
      expect(withMiss, lessThan(withoutMiss));
    });

    test('VIP catches are worth more than normal catches', () {
      final normal = calculateRushHourScore(
        passengersHandled: 1,
        passengersMissed: 0,
      );
      final vip = calculateRushHourScore(
        passengersHandled: 0,
        passengersMissed: 0,
        vipHandled: 1,
      );
      expect(vip, greaterThan(normal));
    });

    test('missing a VIP costs more than missing a normal passenger', () {
      // handled=10 keeps both scores well above the zero floor so the
      // penalty difference is actually observable.
      final normalMiss = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 1,
      );
      final vipMiss = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 0,
        vipMissed: 1,
      );
      expect(vipMiss, lessThan(normalMiss));
    });

    test('tapping an obstacle passenger is penalized', () {
      final withObstacleTap = calculateRushHourScore(
        passengersHandled: 5,
        passengersMissed: 0,
        obstaclesTapped: 1,
      );
      final withoutObstacleTap = calculateRushHourScore(
        passengersHandled: 5,
        passengersMissed: 0,
      );
      expect(withObstacleTap, lessThan(withoutObstacleTap));
    });

    test('a longer combo adds a bonus', () {
      final withCombo = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 0,
        longestCombo: 10,
      );
      final withoutCombo = calculateRushHourScore(
        passengersHandled: 10,
        passengersMissed: 0,
      );
      expect(withCombo, greaterThan(withoutCombo));
    });

    test('never returns a negative score', () {
      final score = calculateRushHourScore(
        passengersHandled: 0,
        passengersMissed: 20,
      );
      expect(score, 0);
    });
  });

  group('calculateComboBonus', () {
    test('no bonus below the first tier', () {
      expect(calculateComboBonus(4), 0);
    });

    test('bonus increases every 5-combo tier', () {
      expect(calculateComboBonus(5), 50);
      expect(calculateComboBonus(10), 100);
      expect(calculateComboBonus(14), 100);
    });
  });

  group('calculateSpawnInterval', () {
    test('stays at the base interval right at the start', () {
      final interval = calculateSpawnInterval(
        elapsedSeconds: 0,
        baseIntervalSeconds: 0.8,
        minIntervalSeconds: 0.3,
      );
      expect(interval, 0.8);
    });

    test('shrinks as time passes', () {
      final early = calculateSpawnInterval(
        elapsedSeconds: 0,
        baseIntervalSeconds: 0.8,
        minIntervalSeconds: 0.3,
      );
      final later = calculateSpawnInterval(
        elapsedSeconds: 20,
        baseIntervalSeconds: 0.8,
        minIntervalSeconds: 0.3,
      );
      expect(later, lessThan(early));
    });

    test('never goes below the configured minimum', () {
      final interval = calculateSpawnInterval(
        elapsedSeconds: 1000,
        baseIntervalSeconds: 0.8,
        minIntervalSeconds: 0.3,
      );
      expect(interval, closeTo(0.3, 0.0001));
    });

    test('reaches the minimum by the end of a real 30-second round', () {
      final interval = calculateSpawnInterval(
        elapsedSeconds: 30,
        baseIntervalSeconds: 0.8,
        minIntervalSeconds: 0.3,
        rampDurationSeconds: 30,
      );
      expect(interval, closeTo(0.3, 0.0001));
    });
  });
}
