import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/validators.dart';
import '../models/app_user.dart';
import '../models/incident_enums.dart';

/// Data layer for authentication and the `users` collection.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  Stream<AppUser?> profile(String uid) => _userDoc(uid).snapshots().map(
        (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
      );

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!Validators.isAluEmail(email)) {
      throw ArgumentError('Only ALU email addresses can register.');
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(name.trim());

    final profile = AppUser(uid: user.uid, name: name.trim(), email: email.trim().toLowerCase(), role: UserRole.student);
    await _userDoc(user.uid).set(profile.toNewUserMap());
    await user.sendEmailVerification();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (!Validators.isAluEmail(email)) {
      throw ArgumentError('Use your ALU email address.');
    }
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async => _auth.currentUser?.sendEmailVerification();

  /// Reloads the user and refreshes the ID token so security rules see
  /// `email_verified == true` immediately after the link is clicked.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final fresh = _auth.currentUser;
    if (fresh != null && fresh.emailVerified) {
      await fresh.getIdToken(true);
      return true;
    }
    return false;
  }

  /// Creates a missing profile (e.g. an account made in the console).
  Future<void> ensureProfile(User user) async {
    final doc = await _userDoc(user.uid).get();
    if (doc.exists) return;
    final profile = AppUser(
      uid: user.uid,
      name: user.displayName ?? (user.email ?? '').split('@').first,
      email: (user.email ?? '').toLowerCase(),
      role: UserRole.student,
    );
    await _userDoc(user.uid).set(profile.toNewUserMap());
  }

  /// Staff only: look up the real reporter of an anonymous report.
  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null;
  }
}