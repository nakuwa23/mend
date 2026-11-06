import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldown = 60;
  int _secondsLeft = _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsLeft = _cooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      if (mounted) setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, _cooldown));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification();
    if (!mounted) return;
    showMessage(context, ok ? 'Verification link sent again.' : auth.error!);
    if (ok) setState(_startCooldown);
  }

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.checkVerified();
    if (!ok && mounted && auth.error != null) showMessage(context, auth.error!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingEmail ?? 'your ALU email';
    final mm = (_secondsLeft ~/ 60).toString();
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(color: AppColors.slate, borderRadius: BorderRadius.circular(34)),
                  child: const Icon(Icons.mark_email_unread_outlined, color: AppColors.peach, size: 52),
                ),
              ),
              const SizedBox(height: 24),
              Text('Check your inbox', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'We sent a verification link to '),
                  TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: '. Open it to activate your account, then come back here.'),
                ]),
                style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF3C4548)),
              ),
              const SizedBox(height: 20),
              const _Steps(),
              const Spacer(),
              LoadingButton(
                label: 'I\'ve verified · continue',
                accent: true,
                loading: auth.busy,
                onPressed: _continue,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _secondsLeft > 0 || auth.busy ? null : _resend,
                child: Text(_secondsLeft > 0 ? 'Resend link in $mm:$ss' : 'Resend link'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: auth.busy ? null : () => context.read<AuthProvider>().signOut(),
                child: const Text('Use a different email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    Widget row(Widget dot, String text, {bool bold = false, bool muted = false}) => Row(children: [
          dot,
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: muted ? AppColors.muted : AppColors.ink)),
        ]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          row(
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: AppColors.slate, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            'Account created',
          ),
          const SizedBox(height: 12),
          row(
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.peach,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.progressBg, width: 4),
              ),
            ),
            'Verify your email',
            bold: true,
          ),
          const SizedBox(height: 12),
          row(
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9DA3A5), width: 2),
              ),
            ),
            'Start reporting',
            muted: true,
          ),
        ],
      ),
    );
  }
}