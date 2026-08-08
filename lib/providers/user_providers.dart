import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_profile.dart';
import 'service_providers.dart';

/// 現在ログイン中ユーザーの UserProfile を取得する。
/// 存在しなければ Firestore にドキュメントがまだ無い（初回起動）とみなし null を返す。
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userID = await ref.watch(currentUserIdProvider.future);
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getUserProfile(userID);
});
