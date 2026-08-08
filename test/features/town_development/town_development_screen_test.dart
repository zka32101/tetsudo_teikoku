import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/town_development/town_development_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';
import 'package:tetsudo_teikoku/services/firestore_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logTownDeveloped({
    required String stationID,
    required String developmentType,
  }) async {}
}

class _FakeFirestoreService extends FirestoreService {
  DevelopmentType? updatedType;
  TownDevelopment? createdTown;

  @override
  Future<void> updateStationDevelopment(
    String stationID,
    DevelopmentType type,
  ) async {
    updatedType = type;
  }

  @override
  Future<void> createTownDevelopment(TownDevelopment development) async {
    createdTown = development;
  }
}

void main() {
  testWidgets('confirm button stays disabled until a choice is made', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(_FakeFirestoreService()),
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: const MaterialApp(
          home: TownDevelopmentScreen(stationID: 's1'),
        ),
      ),
    );

    final confirmButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('development_confirm_button')),
    );
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('selecting a choice enables confirm and submits it', (
    tester,
  ) async {
    final fakeFirestore = _FakeFirestoreService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(fakeFirestore),
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: const MaterialApp(
          home: TownDevelopmentScreen(stationID: 's1'),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('development_choice_shogyo')));
    await tester.pump();

    final confirmButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('development_confirm_button')),
    );
    expect(confirmButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('development_confirm_button')));
    await tester.pumpAndSettle();

    expect(fakeFirestore.updatedType, DevelopmentType.shogyo);
    expect(fakeFirestore.createdTown?.developmentType, DevelopmentType.shogyo);
  });
}
