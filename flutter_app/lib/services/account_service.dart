import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AccountService {
  AccountService._();
  static final instance = AccountService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  String? get email => _auth.currentUser?.email;
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    final credential = await _auth.signInAnonymously();
    return credential.user!;
  }

  Future<UserCredential> createOrLinkWithEmail(
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim();
    await ensureSignedIn();

    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      final credential = EmailAuthProvider.credential(
        email: trimmedEmail,
        password: password,
      );
      try {
        return await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' &&
            e.code != 'email-already-in-use') {
          rethrow;
        }
        debugPrint('Email is already in use. Signing in instead.');
      }
    }

    return _auth.signInWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOutToAnonymous() async {
    await _auth.signOut();
    await ensureSignedIn();
  }
}
