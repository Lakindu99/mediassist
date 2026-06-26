import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';

/// Wraps all Firebase authentication logic in one place.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Register a new user, saving their name AND role to Firestore.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': AppUser.roleToString(role),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> logout() async => _auth.signOut();

  /// Fetch the current user's full profile (including role) from Firestore.
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(user.uid, doc.data()!);
  }
}

/// Turns Firebase's technical error codes into kind, plain-language messages.
String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return "That email address doesn't look right. Please check it.";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in.';
      case 'weak-password':
        return 'Please choose a longer password (at least 6 characters).';
      case 'network-request-failed':
        return 'No internet connection. Please check and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
