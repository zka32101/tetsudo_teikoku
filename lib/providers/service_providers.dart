import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/revenuecat_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/remote_config/remote_config_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(),
);

final revenueCatServiceProvider = Provider<RevenueCatService>(
  (ref) => RevenueCatService(),
);

/// 現在のサインイン済みユーザーID。未サインインなら AuthService.ensureSignedIn を待つ。
final currentUserIdProvider = FutureProvider<String>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.ensureSignedIn();
});
