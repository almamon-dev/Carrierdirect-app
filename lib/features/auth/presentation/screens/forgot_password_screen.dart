import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/utils/app_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  int _resendSeconds = 60;
  Timer? _timer;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = AppColors.background;
  static const Color inputFill = AppColors.surface;
  static const Color inputBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        _startResendTimer();
        AppToast.success(
          context,
          '✓ Password reset link sent to ${_emailController.text.trim()}',
          icon: Icons.mark_email_read_rounded,
        );
      }
    }
  }

  void _handleResend() async {
    if (_resendSeconds > 0) return;
    _startResendTimer();
    AppToast.success(
      context,
      '✓ New reset link sent to ${_emailController.text.trim()}',
      icon: Icons.send_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain, size: 22),
          onPressed: () {
            if (_emailSent) {
              setState(() => _emailSent = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _emailSent ? 'Email Verification' : 'Forgot Password',
          style: const TextStyle(
            color: textMain,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: _emailSent ? _buildEmailSentView() : _buildInputFormView(),
        ),
      ),
    );
  }

  // 1. Initial Email Input Form View
  Widget _buildInputFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // High Resolution 3D Glossy Lock in Orange Envelope Asset
          Center(
            child: Image.asset(
              'assets/images/forgot_password_lock.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

          // Title Header
          const Text(
            'Reset Your Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textMain,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Enter your registered driver email address and we will send you a secure password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSub,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Email Address Field
          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'driver@example.com',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 24),

          // Send Reset Link Button
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0.5,
                shadowColor: primaryColor.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Back to Login Button
          SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: textMain,
                side: const BorderSide(color: inputBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Email Sent Success Confirmation View (No OTP screen)
  Widget _buildEmailSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Glowing Mail Envelope Circle Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.15),
              border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.mark_email_read_rounded,
                color: primaryColor,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Header Title
        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textMain,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle with user's email
        Text(
          'We have dispatched a password reset link to:',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: textSub),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          alignment: Alignment.center,
          child: Text(
            _emailController.text.trim(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textMain,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Info Instruction Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF1877F2), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Click the reset link in your email to securely set your new password. If you do not see it within a few minutes, check your spam or junk folder.',
                  style: TextStyle(color: textSub, fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive the email? ",
              style: TextStyle(fontSize: 12.5, color: textSub),
            ),
            if (_resendSeconds > 0)
              Text(
                'Resend in ${_resendSeconds}s',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
              )
            else
              GestureDetector(
                onTap: _handleResend,
                child: const Text(
                  'Resend Link',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Return to Login Button
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
