import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tetsudo_teikoku/data/models/index.dart';
import 'package:tetsudo_teikoku/features/timetable/timetable_design_screen.dart';
import 'package:tetsudo_teikoku/providers/service_providers.dart';
import 'package:tetsudo_teikoku/services/analytics/analytics_service.dart';
import 'package:tetsudo_teikoku/services/firestore_service.dart';

class _NoopAnalyticsService extends AnalyticsService {
  @override
  Future<void> logTimetableDesigned({
    required String railroadID,
    required double efficiencyScore,
  }) async {}
}

class _FakeFirestoreService extends FirestoreService {
  TimetableDesign? saved;

  @override
  Future<void> saveTimetableDesign(TimetableDesign timetable) async {
    saved = timetable;
  }
}

void main() {
  testWidgets('save button is disabled until a train is added', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(_FakeFirestoreService()),
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: const MaterialApp(
          home: TimetableDesignScreen(userID: 'u1', railroadID: 'tokaido_line'),
        ),
      ),
    );

    final saveButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('save_timetable_button')),
    );
    expect(saveButton.onPressed, isNull);
    expect(find.text('0.0'), findsOneWidget);
  });

  testWidgets('adding a train updates the list and efficiency score, save persists it', (
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
          home: TimetableDesignScreen(userID: 'u1', railroadID: 'tokaido_line'),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('stops_field')), '東京, 品川, 横浜');
    await tester.tap(find.byKey(const Key('add_train_button')));
    await tester.pump();

    expect(find.byKey(const Key('train_list')), findsOneWidget);
    expect(find.textContaining('08:00 → 08:30'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);

    final saveButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('save_timetable_button')),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('save_timetable_button')));
    await tester.pumpAndSettle();

    expect(fakeFirestore.saved, isNotNull);
    expect(fakeFirestore.saved!.trains.length, 1);
    expect(fakeFirestore.saved!.trains.first.stops, ['東京', '品川', '横浜']);
  });
}
