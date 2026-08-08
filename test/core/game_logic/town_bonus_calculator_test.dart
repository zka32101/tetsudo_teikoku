import 'package:flutter_test/flutter_test.dart';
import 'package:tetsudo_teikoku/core/game_logic/town_bonus_calculator.dart';
import 'package:tetsudo_teikoku/data/models/station.dart';

void main() {
  group('calculateTownBonusFromDevelopment', () {
    test('none development gives no bonus', () {
      expect(calculateTownBonusFromDevelopment(DevelopmentType.none), 1.0);
    });

    test('each development type gives a bonus above 1.0', () {
      for (final type in [
        DevelopmentType.onsen,
        DevelopmentType.shogyo,
        DevelopmentType.kanko,
      ]) {
        expect(calculateTownBonusFromDevelopment(type), greaterThan(1.0));
      }
    });
  });
}
