import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/notification_service.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/wave_processing_indicator.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'terms_conditions_screen.dart';

/// Ultra-Clean Minimalist Flat Dark Login Screen for CarrierDirect Driver App
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  // Ultra-Clean Dark Palette Tokens
  static const Color darkBg = Color(0xFF0F172A); // Clean Slate-900 Canvas
  static const Color cardBg = Color(0xFF1E293B); // Slate-800 Input Fill
  static const Color borderCol = Color(0xFF334155); // Slate-700 Border
  static const Color borderFocus = Color(
    0xFFFF5722,
  ); // CarrierDirect Vibrant Orange
  static const Color textWhite = Color(0xFFF8FAFC); // Clean White Header
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400 Caption
  static const Color primaryOrange = Color(0xFFFF5722); // Brand Orange
  static const Color primaryDarkOrange = Color(0xFFFF3D00); // Gradient End

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDevCredentials() {
    setState(() {
      _emailController.text = 'balbrigganconnected@gmail.com';
      _passwordController.text = 'password';
      _rememberMe = true;
    });
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepository = AuthRepository();
      final user = await authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user.requires2fa && (user.token == null || user.token!.isEmpty)) {
        final targetEmail = user.email.isNotEmpty
            ? user.email
            : _emailController.text.trim();
        await _showTwoFactorVerificationSheet(targetEmail, authRepository);
        return;
      }

      await _navigateAfterAuthenticated(user);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMsg = e.toString();
      if (errorMsg.contains('ApiException:') ||
          errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceFirst(RegExp(r'.*Exception:\s*'), '');
      }

      AppToast.error(
        context,
        errorMsg.isNotEmpty
            ? errorMsg
            : 'Invalid email or password. Please try again.',
        title: 'Authentication Failed',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _navigateAfterAuthenticated(UserModel user) async {
    final isNotificationGranted = await NotificationService().checkPermission();
    if (!mounted) return;

    final status = user.verificationStatus?.toLowerCase();
    final isVerified =
        user.isVerified || status == 'verified' || status == 'approved';

    if (!isVerified) {
      if (status == 'pending_setup') {
        Navigator.of(context).pushReplacementNamed(AppRoutes.profileSetup);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminApproval);
      }
    } else if (isNotificationGranted) {
      NotificationService().syncTokenWithBackend();
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else {
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.notificationPermission);
    }
  }

  Future<void> _showTwoFactorVerificationSheet(
    String email,
    AuthRepository authRepository,
  ) async {
    final codeController = TextEditingController();
    bool isVerifying = false;
    String? inlineError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderCol,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: primaryOrange,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Two-Factor Verification',
                              style: TextStyle(
                                color: textWhite,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the 6-digit verification code from your Authenticator app for $email.',
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: codeController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                        ),
                        decoration: _inputDecoration(
                          hint: '000000',
                          prefixIcon: Icons.pin_outlined,
                        ),
                      ),
                      if (inlineError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          inlineError!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: isVerifying
                              ? null
                              : () async {
                                  final code = codeController.text.trim();
                                  if (code.length != 6) {
                                    setSheetState(() {
                                      inlineError =
                                          'Please enter the 6-digit code.';
                                    });
                                    return;
                                  }
                                  setSheetState(() {
                                    isVerifying = true;
                                    inlineError = null;
                                  });
                                  try {
                                    final verifiedUser = await authRepository
                                        .verify2faLogin(
                                          email: email,
                                          code: code,
                                        );
                                    if (!ctx.mounted) return;
                                    Navigator.of(ctx).pop();
                                    await _navigateAfterAuthenticated(
                                      verifiedUser,
                                    );
                                  } catch (err) {
                                    String msg = err.toString().replaceFirst(
                                      RegExp(r'.*Exception:\s*'),
                                      '',
                                    );
                                    setSheetState(() {
                                      isVerifying = false;
                                      inlineError = msg.isNotEmpty
                                          ? msg
                                          : 'Invalid verification code.';
                                    });
                                  }
                                },
                          child: isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Verify & Sign In',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // 1. Brand Logo with subtle touch to splash
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.splash),
                      child: Image.asset(
                        'assets/images/Logo.png',
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Carrier',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Direct',
                                style: TextStyle(color: primaryOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Clean Modern Header
                  const Text(
                    'Driver Sign In',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your credentials to access your route and loads.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. Email Input
                  _buildInputLabel('Email Address'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hint: 'balbrigganconnected@gmail.com',
                      prefixIcon: Icons.mail_outline_rounded,
                    ),
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: 18),

                  // 4. Password Input & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputLabel('Password'),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.forgotPassword);
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      color: textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textMuted,
                          size: 19,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),

                  const SizedBox(height: 14),

                  // 5. Remember Me & Demo Fill Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: primaryOrange,
                                checkColor: Colors.white,
                                side: const BorderSide(
                                  color: borderCol,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _rememberMe = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Demo Fill
                      GestureDetector(
                        onTap: _fillDevCredentials,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(5.0),
                            border: Border.all(
                              color: primaryOrange.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: primaryOrange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Demo Fill',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // 6. Sign In Button with rounded-[5px]
                  Container(
                    height: 52,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [primaryOrange, primaryDarkOrange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(5.0),
                        splashColor: Colors.white24,
                        child: Center(
                          child: _isLoading
                              ? const WaveProcessingIndicator(
                                  color: Colors.white,
                                  barCount: 4,
                                  maxHeight: 18,
                                  minHeight: 6,
                                  barWidth: 3.5,
                                  barSpacing: 3.5,
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 7. Dispatch Support Link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        AppToast.info(
                          context,
                          'Dispatch Support 24/7: +1 (800) 555-0199',
                          icon: Icons.headset_mic_rounded,
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.headset_mic_outlined,
                            size: 15,
                            color: textMuted,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Need dispatch help? ',
                            style: TextStyle(fontSize: 12.5, color: textMuted),
                          ),
                          Text(
                            'Contact Fleet',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 8. Terms and Privacy Link
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'By signing in, you agree to CarrierDirect ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms',
                            style: const TextStyle(
                              color: primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                TermsConditionsScreen.showModal(
                                  context,
                                  initialTabIndex: 0,
                                );
                              },
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                TermsConditionsScreen.showModal(
                                  context,
                                  initialTabIndex: 1,
                                );
                              },
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: bottomInset + 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textWhite,
        letterSpacing: -0.1,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(prefixIcon, size: 19, color: textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
        borderSide: const BorderSide(color: borderCol, width: 1.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
        borderSide: const BorderSide(color: borderCol, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
        borderSide: const BorderSide(color: borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
