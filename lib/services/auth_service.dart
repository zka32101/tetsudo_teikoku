import 'package:firebase_auth/firebase_auth.dart';

/// 匿名認証を扱う。鉄道帝国は初回起動時にログイン不要で開始できる。
class AuthService {
  final FirebaseAuth? _authOverride;

  AuthService({FirebaseAuth? auth}) : _authOverride = auth;

  // Firebase.instance へのアクセスは初回利用時まで遅延させる。
  // Phase 2でFirebase本設定が終わるまではこのgetterに触れないこと
  // （Firebase.initializeApp()未実行だと即座に例外になる）。
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// サインイン済みユーザーがいなければ匿名サインインする。uid を返す。
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in returned a null user');
    }
    return user.uid;
  }
}
