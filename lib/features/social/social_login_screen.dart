import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/social_provider.dart';
import '../../services/grit_api_service.dart';
import '../../shared/widgets/grit_button.dart';

class SocialLoginScreen extends ConsumerStatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  ConsumerState<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends ConsumerState<SocialLoginScreen> {
  bool _isSignup = false;
  bool _isLoading = false;
  String? _error;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _identifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _identifierController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSignup && _passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = "Passwords don't match");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignup) {
        await ref.read(socialAuthProvider.notifier).register(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              mobileNumber: _mobileController.text.trim(),
              password: _passwordController.text,
            );
      } else {
        await ref.read(socialAuthProvider.notifier).login(
              identifier: _identifierController.text.trim(),
              password: _loginPasswordController.text,
            );
      }
      GritHaptics.mediumImpact();
      // No explicit navigation needed — the router redirects away from the
      // login screen automatically once socialAuthProvider reports logged in.
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Could not reach the server. Check your connection.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: grit.border, width: 1))),
          child: SafeArea(
            child: Text(_isSignup ? 'CREATE ACCOUNT' : 'LOG IN',
                style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Connect with friends, post PRs and workouts, and see what your friends are training.',
              style: GritTextStyles.label(13, color: grit.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            if (_isSignup) ..._signupFields(grit) else ..._loginFields(grit),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GritTextStyles.label(12, color: grit.failureSet)),
            ],
            const SizedBox(height: 24),
            GritPrimaryButton(
              label: _isSignup ? 'SIGN UP' : 'LOG IN',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isSignup = !_isSignup;
                  _error = null;
                }),
                child: Text(
                  _isSignup ? 'Already have an account? Log in' : "Don't have an account? Sign up",
                  style: GritTextStyles.label(12, color: grit.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _signupFields(GritThemeData grit) {
    return [
      _field(grit, _firstNameController, 'FIRST NAME'),
      const SizedBox(height: 12),
      _field(grit, _lastNameController, 'LAST NAME'),
      const SizedBox(height: 12),
      _field(grit, _mobileController, 'MOBILE NUMBER', keyboardType: TextInputType.phone),
      const SizedBox(height: 12),
      _field(grit, _emailController, 'EMAIL', keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      _field(grit, _passwordController, 'PASSWORD', obscure: true),
      const SizedBox(height: 12),
      _field(grit, _confirmPasswordController, 'CONFIRM PASSWORD', obscure: true),
    ];
  }

  List<Widget> _loginFields(GritThemeData grit) {
    return [
      _field(grit, _identifierController, 'EMAIL OR MOBILE NUMBER'),
      const SizedBox(height: 12),
      _field(grit, _loginPasswordController, 'PASSWORD', obscure: true),
    ];
  }

  Widget _field(
    GritThemeData grit,
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GritTextStyles.label(13, color: grit.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary),
      ),
    );
  }
}
