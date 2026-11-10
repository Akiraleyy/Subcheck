import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../controllers/settings_controller.dart';
import '../widgets/common.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// The "SubCheck" title and the small line under it.
Widget _header(BuildContext context, String subtitle) => Column(children: [
      const SizedBox(height: 12),
      Text('SubCheck',
          style: TextStyle(
              color: context.ink, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted, fontSize: 12)),
      const SizedBox(height: 20),
    ]);

/// Figure 10. Create Account (optional, for cloud backup).
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final settings = context.read<SettingsController>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final ok = await settings.createAccount(
          _name.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      if (ok) {
        showSnack(context, 'Account created. You can now back up your data.');
        navigator.popUntil((route) => route.isFirst);
      } else {
        setState(() => _busy = false);
        showSnack(context, settings.errorMessage ?? 'Could not create the account.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, 'Something went wrong. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _header(context, 'Create an account to back up your data to the cloud'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (v) => _emailPattern.hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter a valid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
                validator: (v) =>
                    (v ?? '').length < 6 ? 'Use at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Confirm password'),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Creating…' : 'Create account'),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LogInScreen())),
                  child: Text.rich(TextSpan(
                    style: TextStyle(color: context.muted, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                              color: context.ink, fontWeight: FontWeight.w900)),
                    ],
                  )),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Skipping this keeps SubCheck fully offline',
                      style: TextStyle(color: context.muted, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figure 11. Log In (optional, for cloud backup).
class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final settings = context.read<SettingsController>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final ok = await settings.logIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (ok) {
        showSnack(context, 'Logged in.');
        navigator.popUntil((route) => route.isFirst);
      } else {
        setState(() => _busy = false);
        showSnack(context, settings.errorMessage ?? 'Could not log in.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, 'Something went wrong. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _header(context, "Log in to sync this device's data"),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (v) => _emailPattern.hasMatch((v ?? '').trim())
                    ? null
                    : 'Enter a valid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your password' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Logging in…' : 'Log in'),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateAccountScreen())),
                  child: Text.rich(TextSpan(
                    style: TextStyle(color: context.muted, fontSize: 12),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                          text: 'Create one',
                          style: TextStyle(
                              color: context.ink, fontWeight: FontWeight.w900)),
                    ],
                  )),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Skipping this keeps SubCheck fully offline',
                      style: TextStyle(color: context.muted, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
