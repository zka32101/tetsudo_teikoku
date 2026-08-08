import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/town_growth_calculator.dart';
import 'package:tetsudo_teikoku/data/models/index.dart';

TownDevelopment _development({
  int level = 1,
  int aesthetics = 50,
  int liveliness = 50,
}) {
  return TownDevelopment(
    townID: 's1_town',
    stationID: 's1',
    developmentType: DevelopmentType.onsen,
    level: level,
    aesthetics: aesthetics,
    liveliness: liveliness,
    visualAssetID: null,
    selectedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('applyRevenueGrowth', () {
    test('revenue increases aesthetics and liveliness', () {
      final result = applyRevenueGrowth(_development(), 2000);
      expect(result.aesthetics, greaterThan(50));
      expect(result.liveliness, greaterThan(50));
    });

    test('zero revenue does not decrease existing stats', () {
      final result = applyRevenueGrowth(_development(), 0);
      expect(result.aesthetics, 50);
      expect(result.liveliness, 50);
    });

    test('stats never exceed 100', () {
      final result = applyRevenueGrowth(
        _development(aesthetics: 99, liveliness: 99),
        100000,
      );
      expect(result.aesthetics, lessThanOrEqualTo(100));
      expect(result.liveliness, lessThanOrEqualTo(100));
    });

    test('level increases once average growth crosses a tier boundary', () {
      final result = applyRevenueGrowth(
        _development(aesthetics: 95, liveliness: 95),
        100000,
      );
      expect(result.level, greaterThan(1));
    });

    test('level never exceeds the cap of 6', () {
      final result = applyRevenueGrowth(
        _development(aesthetics: 100, liveliness: 100),
        100000,
      );
      expect(result.level, lessThanOrEqualTo(6));
    });

    test('preserves identity fields unrelated to growth', () {
      final development = _development();
      final result = applyRevenueGrowth(development, 500);
      expect(result.townID, development.townID);
      expect(result.stationID, development.stationID);
      expect(result.developmentType, development.developmentType);
      expect(result.selectedAt, development.selectedAt);
    });
  });
}
