import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/index.dart';

/// 設計書 §4 データモデルの10コレクションへの CRUD アクセス。
/// Aha Moment 動線（駅員配置→収益計算→町の発展）に必要な操作を優先実装。
class FirestoreService {
  final FirebaseFirestore? _dbOverride;

  FirestoreService({FirebaseFirestore? firestore}) : _dbOverride = firestore;

  // Firebase.instance へのアクセスは初回利用時まで遅延させる（AuthService参照）。
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _railroads =>
      _db.collection('railroads');
  CollectionReference<Map<String, dynamic>> get _stations =>
      _db.collection('stations');
  CollectionReference<Map<String, dynamic>> get _staff =>
      _db.collection('station_staff');
  CollectionReference<Map<String, dynamic>> get _teams =>
      _db.collection('team_formations');
  CollectionReference<Map<String, dynamic>> get _townDevelopments =>
      _db.collection('town_developments');
  CollectionReference<Map<String, dynamic>> get _timetables =>
      _db.collection('timetable_designs');
  CollectionReference<Map<String, dynamic>> get _rankings =>
      _db.collection('rankings');
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  // ---------------------------------------------------------------------
  // users
  // ---------------------------------------------------------------------

  Future<UserProfile?> getUserProfile(String userID) async {
    final doc = await _users.doc(userID).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(doc.data()!);
  }

  Future<void> createUserProfile(UserProfile profile) async {
    return _users.doc(profile.userID).set(profile.toJson());
  }

  Future<void> updateUserMoney(String userID, {required int currentMoney, required int totalMoney}) async {
    return _users.doc(userID).update({
      'currentMoney': currentMoney,
      'totalMoney': totalMoney,
    });
  }

  // ---------------------------------------------------------------------
  // railroads / stations (全員読み取り可・Cloud Function経由で書き込み)
  // ---------------------------------------------------------------------

  Future<Railroad?> getRailroad(String railroadID) async {
    final doc = await _railroads.doc(railroadID).get();
    if (!doc.exists) return null;
    return Railroad.fromJson(doc.data()!);
  }

  Future<Station?> getStation(String stationID) async {
    final doc = await _stations.doc(stationID).get();
    if (!doc.exists) return null;
    return Station.fromJson(doc.data()!);
  }

  Future<List<Station>> getStationsByRailroad(String railroadID) async {
    final snapshot = await _stations
        .where('railroadID', isEqualTo: railroadID)
        .get();
    return snapshot.docs.map((doc) => Station.fromJson(doc.data())).toList();
  }

  Future<void> updateStationDevelopment(
    String stationID,
    DevelopmentType type,
  ) async {
    return _stations.doc(stationID).update({
      'developmentType': developmentTypeToString(type),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------
  // station_staff / team_formations
  // ---------------------------------------------------------------------

  Future<List<StationStaff>> getStaffByStation(String stationID) async {
    final snapshot = await _staff.where('stationID', isEqualTo: stationID).get();
    return snapshot.docs
        .map((doc) => StationStaff.fromJson(doc.data()))
        .toList();
  }

  Future<void> createTeamFormation(TeamFormation team) async {
    return _teams.doc(team.teamID).set(team.toJson());
  }

  // ---------------------------------------------------------------------
  // town_developments
  // ---------------------------------------------------------------------

  Future<void> createTownDevelopment(TownDevelopment development) async {
    return _townDevelopments.doc(development.townID).set(development.toJson());
  }

  Future<TownDevelopment?> getTownDevelopment(String stationID) async {
    final snapshot = await _townDevelopments
        .where('stationID', isEqualTo: stationID)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return TownDevelopment.fromJson(snapshot.docs.first.data());
  }

  // ---------------------------------------------------------------------
  // timetable_designs
  // ---------------------------------------------------------------------

  Future<void> saveTimetableDesign(TimetableDesign timetable) async {
    return _timetables.doc(timetable.timetableID).set(timetable.toJson());
  }

  // ---------------------------------------------------------------------
  // rankings (書き込みは Cloud Function のみ)
  // ---------------------------------------------------------------------

  Future<List<PvPRanking>> getTopRankings({int limit = 100}) async {
    final snapshot = await _rankings.orderBy('rank').limit(limit).get();
    return snapshot.docs.map((doc) => PvPRanking.fromJson(doc.data())).toList();
  }

  // ---------------------------------------------------------------------
  // events
  // ---------------------------------------------------------------------

  Future<List<GameEvent>> getActiveEvents() async {
    final now = Timestamp.now();
    final snapshot = await _events
        .where('endTime', isGreaterThan: now)
        .get();
    return snapshot.docs.map((doc) => GameEvent.fromJson(doc.data())).toList();
  }
}
