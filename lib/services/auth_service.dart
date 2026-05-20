import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  Future<UserCredential?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null;
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  // 匿名アカウントをGoogleアカウントに昇格（データはそのまま引き継がれる）
  Future<UserCredential?> linkWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null;
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.currentUser?.linkWithCredential(credential);
  }

  Future<void> signOut() async {
    try { await _google.signOut(); } catch (_) {}
    await _auth.signOut();
  }

  // Firestoreデータ削除はFirestoreServiceで行ってから呼ぶこと
  Future<void> deleteAccount() async {
    await _google.signOut();
    await _auth.currentUser?.delete();
  }
}
