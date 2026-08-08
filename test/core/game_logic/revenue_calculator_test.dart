import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/revenue_calculator.dart';
import 'package:tetsudo_teikoku/data/models/index.dart';

StationStaff _staff({int efficiency = 50}) {
  return StationStaff(
    staffID: 's',
    stationID: 'st1',
    userID: 'u1',
    name: 's',
    rarity: StaffRarity.r,
    stats: StaffStats(hospitality: 50, efficiency: efficiency, kindness: 50),
    level: 1,
    exp: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('calculateMonthlyRevenue', () {
    test('no staff still yields base revenue from passengers', () {
      final revenue = calculateMonthlyRevenue(
        staff: [],
        developmentType: DevelopmentType.none,
        passengersPerDay: 100,
      );
      expect(revenue, 100 * 2);
    });

    test('more staff efficiency increases revenue', () {
      final low = calculateMonthlyRevenue(
        staff: [_staff(efficiency: 10)],
        developmentType: DevelopmentType.none,
        passengersPerDay: 0,
      );
      final high = calculateMonthlyRevenue(
        staff: [_staff(efficiency: 90)],
        developmentType: DevelopmentType.none,
        passengersPerDay: 0,
      );
      expect(high, greaterThan(low));
    });

    test('development bonus multiplies the total', () {
      final none = calculateMonthlyRevenue(
        staff: [_staff(efficiency: 50)],
        developmentType: DevelopmentType.none,
        passengersPerDay: 100,
      );
      final shogyo = calculateMonthlyRevenue(
        staff: [_staff(efficiency: 50)],
        developmentType: DevelopmentType.shogyo,
        passengersPerDay: 100,
      );
      expect(shogyo, greaterThan(none));
    });
  });
}
