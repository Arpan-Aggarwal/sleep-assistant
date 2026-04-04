import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      print('[Auth] Starting signup for $email');

      final credential = await _auth
          .createUserWithEmailAndPassword(
            email:    email,
            password: password,
          )
          .timeout(const Duration(seconds: 20));

      final userId = credential.user!.uid;
      print('[Auth] Signup successful: $userId');

      await StorageService.updatePref('user_id',        userId);
      await StorageService.updatePref('setup_complete', false);

      return {'success': true, 'user_id': userId};

    } on TimeoutException {
      print('[Auth] Signup timed out');
      return {
        'success': false,
        'error':   'Connection timed out. Check your internet.'
      };
    } on FirebaseAuthException catch (e) {
      print('[Auth] Firebase error: ${e.code}');
      return {'success': false, 'error': _parseError(e.code)};
    } catch (e) {
      print('[Auth] Unknown error: $e');
      return {
        'success': false,
        'error':   'Something went wrong. Try again.'
      };
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('[Auth] Starting signin for $email');

      final credential = await _auth
          .signInWithEmailAndPassword(
            email:    email,
            password: password,
          )
          .timeout(const Duration(seconds: 20));

      final userId = credential.user!.uid;
      print('[Auth] Signin successful: $userId');

      await StorageService.updatePref('user_id',        userId);
      await StorageService.updatePref('setup_complete', true);

      return {'success': true, 'user_id': userId};

    } on TimeoutException {
      print('[Auth] Signin timed out');
      return {
        'success': false,
        'error':   'Connection timed out. Check your internet.'
      };
    } on FirebaseAuthException catch (e) {
      print('[Auth] Firebase error: ${e.code}');
      return {'success': false, 'error': _parseError(e.code)};
    } catch (e) {
      print('[Auth] Unknown error: $e');
      return {
        'success': false,
        'error':   'Something went wrong. Try again.'
      };
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User?  get currentUser => _auth.currentUser;
  static bool   get isLoggedIn  => _auth.currentUser != null;

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