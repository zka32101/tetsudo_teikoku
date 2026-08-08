import 'package:firebase_remote_config/firebase_remote_config.dart';

/// 設計書 §7 Remote Config で定義されたキー。
class RemoteConfigKeys {
  static const ahaThreshold = 'aha_threshold';
  static const paywallDelayHours = 'paywall_delay_hours';
  static const difficultyMultiplier = 'difficulty_multiplier';
  static const minSupportedVersion = 'min_supported_version';
}

class RemoteConfigService {
  final FirebaseRemoteConfig? _remoteConfigOverride;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfigOverride = remoteConfig;

  // Firebase.instance へのアクセスは初回利用時まで遅延させる（AuthService参照）。
  FirebaseRemoteConfig get _remoteConfig =>
      _remoteConfigOverride ?? FirebaseRemoteConfig.instance;

  static const _defaults = <String, Object>{
    RemoteConfigKeys.ahaThreshold: 1,
    RemoteConfigKeys.paywallDelayHours: 0,
    RemoteConfigKeys.difficultyMultiplier: 1.0,
    RemoteConfigKeys.minSupportedVersion: '1.0.0',
  };

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.setDefaults(_defaults);
    await _remoteConfig.fetchAndActivate();
  }

  // 同期getterのままだとFirebase未初期化時の例外をcatchErrorで捕まえられない
  // （AnalyticsServiceと同じ理由）ため、全てasyncメソッドにしている。
  Future<int> getAhaThreshold() async =>
      _remoteConfig.getInt(RemoteConfigKeys.ahaThreshold);

  Future<int> getPaywallDelayHours() async =>
      _remoteConfig.getInt(RemoteConfigKeys.paywallDelayHours);

  Future<double> getDifficultyMultiplier() async =>
      _remoteConfig.getDouble(RemoteConfigKeys.difficultyMultiplier);

  Future<String> getMinSupportedVersion() async =>
      _remoteConfig.getString(RemoteConfigKeys.minSupportedVersion);
}
