import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/compatibility_calculator.dart';
import 'package:tetsudo_teikoku/data/models/station_staff.dart';

StationStaff _staff(String id, {int hospitality = 50, int efficiency = 50, int kindness = 50}) {
  return StationStaff(
    staffID: id,
    stationID: 'st1',
    userID: 'u1',
    name: id,
    rarity: StaffRarity.r,
    stats: StaffStats(
      hospitality: hospitality,
      efficiency: efficiency,
      kindness: kindness,
    ),
    level: 1,
    exp: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('calculateCompatibilityBonus', () {
    test('identical stats give the max bonus', () {
      final a = _staff('a', hospitality: 50, efficiency: 50, kindness: 50);
      final b = _staff('b', hospitality: 50, efficiency: 50, kindness: 50);
      expect(calculateCompatibilityBonus(a, b), 1.5);
    });

    test('large stat gap is clamped to the minimum bonus', () {
      final a = _staff('a', hospitality: 0, efficiency: 0, kindness: 0);
      final b = _staff('b', hospitality: 100, efficiency: 100, kindness: 100);
      expect(calculateCompatibilityBonus(a, b), 0.8);
    });

    test('moderate gap gives a bonus between the bounds', () {
      final a = _staff('a', hospitality: 50, efficiency: 50, kindness: 50);
      final b = _staff('b', hospitality: 60, efficiency: 50, kindness: 50);
      final bonus = calculateCompatibilityBonus(a, b);
      expect(bonus, lessThan(1.5));
      expect(bonus, greaterThan(0.8));
    });
  });

  group('calculateTotalEfficiency', () {
    test('scales with average efficiency and compatibility bonus', () {
      final a = _staff('a', efficiency: 60);
      final b = _staff('b', efficiency: 40);
      // avg efficiency = 50, diff = |60-40| = 20 → bonus = 1.5 - 0.2 = 1.3
      expect(calculateTotalEfficiency(a, b), 65.0);
    });
  });
}
