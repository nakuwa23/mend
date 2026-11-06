import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_email.text, _password.text);
    if (!ok && mounted && auth.error != null) showMessage(context, auth.error!);
  }

  Future<void> _forgotPassword() async {
    final error = Validators.aluEmail(_email.text);
    if (error != null) {
      showMessage(context, 'Enter your ALU email above first.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_email.text);
    if (mounted) showMessage(context, ok ? 'Reset link sent to ${_email.text.trim()}' : auth.error!);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Sign in with your ALU email', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text('Students and Facilities staff use the same app.',
                          style: TextStyle(color: AppColors.muted, fontSize: 14)),
                      const SizedBox(height: 20),
                      const FieldLabel('Email'),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: Validators.aluEmail,
                        decoration: const InputDecoration(
                          hintText: 'name@alustudent.com',
                          prefixIcon: Icon(Icons.mail_outline),
                          helperText: 'Only @alustudent.com and @alueducation.com addresses',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FieldLabel('Password',
                          trailing: GestureDetector(
                            onTap: busy ? null : _forgotPassword,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Forgot?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate)),
                            ),
                          )),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: Validators.signInPassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Show password' : 'Hide password',
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LoadingButton(label: 'Sign in', accent: true, loading: busy, onPressed: _submit),
                      const SizedBox(height: 16),
                      const InfoBanner(
                        icon: Icons.verified_user_outlined,
                        child: Text('New accounts get a verification link by email. You can report once it\'s confirmed.'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('New to Mend?', style: TextStyle(color: AppColors.muted)),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                    ),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final display = Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontSize: 34, height: 1.12);
    return Container(
      color: AppColors.slate,
      padding: EdgeInsets.fromLTRB(28, MediaQuery.of(context).padding.top + 32, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.where_to_vote_outlined, color: AppColors.slate),
            ),
            const SizedBox(width: 10),
            Text('Mend', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22)),
          ]),
          const SizedBox(height: 56),
          Text('Spot it.\nReport it.', style: display),
          Text('See it fixed.', style: display?.copyWith(color: AppColors.peach)),
        ],
      ),
    );
  }
}