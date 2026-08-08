import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/index.dart';
import 'service_providers.dart';

final stationsByRailroadProvider =
    FutureProvider.family<List<Station>, String>((ref, railroadID) {
      final firestore = ref.watch(firestoreServiceProvider);
      return firestore.getStationsByRailroad(railroadID);
    });

final stationDetailProvider = FutureProvider.family<Station?, String>((
  ref,
  stationID,
) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getStation(stationID);
});

final staffByStationProvider =
    FutureProvider.family<List<StationStaff>, String>((ref, stationID) {
      final firestore = ref.watch(firestoreServiceProvider);
      return firestore.getStaffByStation(stationID);
    });

final townDevelopmentProvider =
    FutureProvider.family<TownDevelopment?, String>((ref, stationID) {
      final firestore = ref.watch(firestoreServiceProvider);
      return firestore.getTownDevelopment(stationID);
    });

final activeEventsProvider = FutureProvider<List<GameEvent>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getActiveEvents();
});

final topRankingsProvider = FutureProvider<List<PvPRanking>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getTopRankings();
});
