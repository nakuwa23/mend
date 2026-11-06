import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../staff/staff_shell.dart';
import '../student/student_shell.dart';
import 'sign_in_screen.dart';
import 'verify_email_screen.dart';

/// Decides what the user sees from the auth state.
/// The role comes from Firestore (users/{uid}.role), never from the user.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final Widget child = switch (auth.status) {
      AuthStatus.loading => const _Splash(),
      AuthStatus.signedOut => const SignInScreen(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.ready => auth.isStaff ? const StaffShell() : const StudentShell(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey('${auth.status}-${auth.isStaff}'), child: child),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.slate,
      body: Center(child: CircularProgressIndicator(color: AppColors.peach)),
    );
  }
}