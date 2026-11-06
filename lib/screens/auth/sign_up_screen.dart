import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(_name.text, _email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.error != null) {
      showMessage(context, auth.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 1 of 2', style: TextStyle(fontSize: 13, color: AppColors.muted))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create your account', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Text('Use your ALU email so Facilities knows the report comes from campus.',
                    style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.45)),
                const SizedBox(height: 20),
                const FieldLabel('Full name'),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                const FieldLabel('ALU email'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.aluEmail,
                  decoration: const InputDecoration(hintText: 'name@alustudent.com'),
                ),
                const SizedBox(height: 16),
                const FieldLabel('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  decoration: InputDecoration(
                    helperText: '8+ characters with a number',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const FieldLabel('Confirm password'),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.confirmPassword(() => _password.text),
                ),
                const SizedBox(height: 20),
                const InfoBanner(
                  icon: Icons.person_outline,
                  child: Text('Every account starts as a student. Facilities staff are given access by an admin.'),
                ),
                const SizedBox(height: 20),
                LoadingButton(label: 'Create account', loading: busy, onPressed: _submit),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have one?', style: TextStyle(color: AppColors.muted)),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Sign in')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}