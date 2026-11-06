import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Turns Firebase exceptions into short messages a student can act on.
String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address isn\'t valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact Facilities.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
    }
    return error.message ?? 'Something went wrong signing in.';
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You don\'t have permission to do that.';
      case 'unavailable':
        return 'The service is unavailable. Check your connection.';
      case 'unauthorized':
        return 'Upload not allowed. Check the photo is under 5 MB.';
    }
    return error.message ?? 'Something went wrong. Please try again.';
  }
  if (error is ArgumentError || error is StateError) {
    return error.toString().replaceFirst(RegExp(r'^(Invalid argument\(s\)|Bad state): '), '');
  }
  return 'Something went wrong. Please try again.';
}