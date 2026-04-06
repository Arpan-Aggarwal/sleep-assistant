// lib/services/auth_service.dart
// Firebase Authentication

import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Sign up ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email:    email,
            password: password,
          );

      final userId = credential.user!.uid;
      await StorageService.updatePref('user_id', userId);

      print('[Auth] Sign up successful: $email');
      return {'success': true, 'user_id': userId};

    } on FirebaseAuthException catch (e) {
      final error = _parseError(e.code);
      print('[Auth] Sign up failed: $error');
      return {'success': false, 'error': error};
    }
  }

  // ── Sign in ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email:    email,
            password: password,
          );

      final userId = credential.user!.uid;
      await StorageService.updatePref('user_id', userId);
      await StorageService.updatePref('setup_complete', true);

      print('[Auth] Sign in successful: $email');
      return {'success': true, 'user_id': userId};

    } on FirebaseAuthException catch (e) {
      final error = _parseError(e.code);
      print('[Auth] Sign in failed: $error');
      return {'success': false, 'error': error};
    }
  }

  // ── Sign out ─────────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
    print('[Auth] Signed out');
  }

  // ── Current user ─────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn   => _auth.currentUser != null;

  // ── Error parser ─────────────────────────────────────────
  static String _parseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Something went wrong. Try again';
    }
  }
}