import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/firebase_errors.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, signedOut, unverified, ready }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _authSub = _service.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _service;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AuthStatus _status = AuthStatus.loading;
  AppUser? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isStaff => _user?.isStaff ?? false;
  bool get busy => _busy;
  String? get error => _error;
  String? get pendingEmail => _service.currentUser?.email;

  AuthService get service => _service;

  void _onAuthChanged(User? firebaseUser) {
    _profileSub?.cancel();
    _profileSub = null;

    if (firebaseUser == null) {
      _user = null;
      _setStatus(AuthStatus.signedOut);
      return;
    }
    if (!firebaseUser.emailVerified) {
      _user = null;
      _setStatus(AuthStatus.unverified);
      return;
    }
    _listenToProfile(firebaseUser);
  }

  void _listenToProfile(User firebaseUser) {
    _setStatus(AuthStatus.loading);
    _profileSub = _service.profile(firebaseUser.uid).listen(
      (profile) async {
        if (profile == null) {
          // Profile missing: create a default student profile once.
          await _service.ensureProfile(firebaseUser);
          return;
        }
        _user = profile;
        _setStatus(AuthStatus.ready);
      },
      onError: (Object e) {
        _error = friendlyError(e);
        _setStatus(AuthStatus.signedOut);
      },
    );
  }

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = friendlyError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email: email, password: password));

  Future<bool> signUp(String name, String email, String password) =>
      _run(() => _service.signUp(name: name, email: email, password: password));

  Future<bool> sendPasswordReset(String email) => _run(() => _service.sendPasswordReset(email));

  Future<bool> resendVerification() => _run(_service.resendVerification);

  Future<bool> checkVerified() async {
    var verified = false;
    final ok = await _run(() async {
      verified = await _service.reloadAndCheckVerified();
      if (!verified) throw StateError('Not verified yet. Open the link in your email first.');
    });
    if (ok && verified) {
      final u = _service.currentUser;
      if (u != null) _listenToProfile(u);
    }
    return ok && verified;
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}