import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../services/notification_service.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/logout_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();
  final LocalStorage _localStorage = LocalStorage();
  final NotificationService _notificationService = NotificationService();

  bool _isLoadingProfile = true;
  bool _isUpdatingNotifications = false;
  bool _pushNotifications = true;

  String _driverName = '';
  String _driverEmail = '';
  String _passwordSubtitle = 'Update your CarrierDirect login password';

  // Exact Design Tokens matching ProfileScreen
  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald200 = Color(0xFFA7F3D0);

  @override
  void initState() {
    super.initState();
    _loadAccountAndSettingsState();
  }

  Future<void> _loadAccountAndSettingsState() async {
    // 1. Hydrate immediately from local cache & OS notification permission
    try {
      final savedEmail = await _localStorage.getString(
        AppConstants.keySavedEmail,
      );
      final cachedPushPref = await _localStorage.getBool(
        AppConstants.keyPushNotificationsEnabled,
      );
      final osGranted = await _notificationService.checkPermission();
      final cachedUserRaw = await _localStorage.getString(
        AppConstants.keyUserData,
      );

      if (cachedUserRaw != null && cachedUserRaw.isNotEmpty) {
        final cached = jsonDecode(cachedUserRaw);
        if (cached is Map<String, dynamic>) {
          _driverName = (cached['full_name'] ?? cached['name'] ?? '')
              .toString()
              .trim();
          _driverEmail = (cached['email'] ?? savedEmail ?? '')
              .toString()
              .trim();
          if (cached['push_notifications_enabled'] is bool) {
            _pushNotifications = cached['push_notifications_enabled'] as bool;
          }
        }
      } else if (savedEmail != null && savedEmail.isNotEmpty) {
        _driverEmail = savedEmail.trim();
      }

      if (cachedPushPref != null) {
        _pushNotifications = cachedPushPref && osGranted;
      } else {
        _pushNotifications = osGranted;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}

    // 2. Fetch live authoritative session & notification preference from API
    try {
      final response = await _apiClient.get(endpoint: ApiConstants.authMe);
      final raw = response.data;
      if (raw is Map) {
        final payload = raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : Map<String, dynamic>.from(raw);
        final name = (payload['name'] ?? payload['full_name'] ?? '')
            .toString()
            .trim();
        final email = (payload['email'] ?? '').toString().trim();
        final serverPush = payload['push_notifications_enabled'] != false;
        final osGranted = await _notificationService.checkPermission();

        if (mounted) {
          setState(() {
            if (name.isNotEmpty) _driverName = name;
            if (email.isNotEmpty) _driverEmail = email;
            _pushNotifications = serverPush && osGranted;
            _isLoadingProfile = false;
          });
        }
        await _persistLocalCache(
          name: _driverName,
          email: _driverEmail,
          pushEnabled: _pushNotifications,
        );
        return;
      }
    } catch (_) {
      // Fallback to /driver/profile if /auth/me fails
      try {
        final profileRes = await _apiClient.get(
          endpoint: ApiConstants.driverProfile,
        );
        final raw = profileRes.data;
        if (raw is Map) {
          final payload = raw['data'] is Map
              ? Map<String, dynamic>.from(raw['data'] as Map)
              : Map<String, dynamic>.from(raw);
          final name = (payload['name'] ?? '').toString().trim();
          final email = (payload['email'] ?? '').toString().trim();
          final serverPush = payload['push_notifications_enabled'] != false;
          final osGranted = await _notificationService.checkPermission();

          if (mounted) {
            setState(() {
              if (name.isNotEmpty) _driverName = name;
              if (email.isNotEmpty) _driverEmail = email;
              _pushNotifications = serverPush && osGranted;
            });
          }
          await _persistLocalCache(
            name: _driverName,
            email: _driverEmail,
            pushEnabled: _pushNotifications,
          );
        }
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _persistLocalCache({
    required String name,
    required String email,
    required bool pushEnabled,
  }) async {
    try {
      await _localStorage.setBool(
        AppConstants.keyPushNotificationsEnabled,
        pushEnabled,
      );

      Map<String, dynamic> merged = {};
      final existingRaw = await _localStorage.getString(
        AppConstants.keyUserData,
      );
      if (existingRaw != null && existingRaw.isNotEmpty) {
        final decoded = jsonDecode(existingRaw);
        if (decoded is Map<String, dynamic>) {
          merged = Map<String, dynamic>.from(decoded);
        }
      }
      if (name.isNotEmpty) merged['full_name'] = name;
      if (email.isNotEmpty) merged['email'] = email;
      merged['push_notifications_enabled'] = pushEnabled;

      await _localStorage.setString(
        AppConstants.keyUserData,
        jsonEncode(merged),
      );
      if (email.isNotEmpty) {
        await _localStorage.setString(AppConstants.keySavedEmail, email);
      }
    } catch (_) {}
  }

  String _cleanError(Object error, String fallback) {
    final raw = error.toString().replaceFirst(RegExp(r'.*Exception:\s*'), '');
    return raw.trim().isNotEmpty ? raw.trim() : fallback;
  }

  Future<void> _handleTogglePushNotifications(bool enable) async {
    if (_isUpdatingNotifications) return;

    setState(() => _isUpdatingNotifications = true);

    try {
      if (enable) {
        final granted = await _notificationService.requestPermissions();
        if (!granted) {
          if (!mounted) return;
          setState(() {
            _pushNotifications = false;
            _isUpdatingNotifications = false;
          });
          AppToast.info(
            context,
            'Please enable notification permission in device settings.',
          );
          return;
        }
      }

      setState(() => _pushNotifications = enable);
      await _persistLocalCache(
        name: _driverName,
        email: _driverEmail,
        pushEnabled: enable,
      );

      await _apiClient.post(
        endpoint: ApiConstants.notificationSettings,
        body: {'push_notifications_enabled': enable},
      );

      if (!mounted) return;
      AppToast.success(
        context,
        enable
            ? 'Push notifications enabled.'
            : 'Push notifications muted.',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        _cleanError(e, 'Could not sync notification preference.'),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingNotifications = false);
      }
    }
  }

  Future<void> _showChangePasswordBottomSheet() async {
    final formKey = GlobalKey<FormState>();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
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
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: slate200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.lock_reset_rounded,
                                color: primaryOrange,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Change App Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: slate900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Set a strong new password for your CarrierDirect driver account (at least 8 characters).',
                            style: TextStyle(color: slate500, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            label: 'New Password',
                            controller: newPasswordCtrl,
                            obscureText: obscureNew,
                            onToggleVisibility: () => setSheetState(
                              () => obscureNew = !obscureNew,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (val.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            label: 'Confirm New Password',
                            controller: confirmPasswordCtrl,
                            obscureText: obscureConfirm,
                            onToggleVisibility: () => setSheetState(
                              () => obscureConfirm = !obscureConfirm,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (val != newPasswordCtrl.text) {
                                return 'Password confirmation does not match';
                              }
                              return null;
                            },
                          ),
                          if (inlineError != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                inlineError!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: slate600,
                                    side: const BorderSide(color: slate200),
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () => Navigator.of(ctx).pop(),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryOrange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          if (!formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          setSheetState(() {
                                            isSaving = true;
                                            inlineError = null;
                                          });
                                          try {
                                            await _apiClient.post(
                                              endpoint:
                                                  ApiConstants.changePassword,
                                              body: {
                                                'new_password':
                                                    newPasswordCtrl.text,
                                                'new_password_confirmation':
                                                    confirmPasswordCtrl.text,
                                              },
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              _passwordSubtitle =
                                                  'Updated just now';
                                            });
                                            if (ctx.mounted) {
                                              Navigator.of(ctx).pop();
                                            }
                                            if (mounted) {
                                              AppToast.success(
                                                context,
                                                'Password changed successfully.',
                                              );
                                            }
                                          } catch (err) {
                                            setSheetState(() {
                                              isSaving = false;
                                              inlineError = _cleanError(
                                                err,
                                                'Failed to update password.',
                                              );
                                            });
                                          }
                                        },
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Update Password',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: slate800,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            color: slate900,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: slate400),
            filled: true,
            fillColor: slate50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: slate500,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: primaryOrange, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = _driverEmail.isNotEmpty
        ? _driverEmail
        : (_isLoadingProfile ? 'Loading account...' : 'Authenticated Driver');

    return Scaffold(
      backgroundColor: slate50,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching ProfileScreen
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 14.0),
                      child: Icon(Icons.arrow_back, size: 22, color: slate900),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'App Settings & Security',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (_isLoadingProfile || _isUpdatingNotifications)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryOrange,
                      ),
                    ),
                ],
              ),
            ),

            // Settings Body
            Expanded(
              child: RefreshIndicator(
                color: primaryOrange,
                onRefresh: _loadAccountAndSettingsState,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  children: [
                    // Section 1: Push Notifications
                    _buildSectionHeader(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                    ),
                    _buildSettingsContainer([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _pushNotifications
                                    ? const Color(0xFFFFF7ED)
                                    : slate100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                size: 18,
                                color: _pushNotifications
                                    ? primaryOrange
                                    : slate600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Push Notifications',
                                    style: TextStyle(
                                      color: slate900,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Receive instant alerts for newly assigned loads & updates',
                                    style: TextStyle(
                                      color: slate500,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _pushNotifications,
                              activeThumbColor: primaryOrange,
                              activeTrackColor: primaryOrange.withValues(
                                alpha: 0.3,
                              ),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: slate200,
                              trackOutlineColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              onChanged: _isUpdatingNotifications
                                  ? null
                                  : _handleTogglePushNotifications,
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    // Section 2: Security & Driver Authentication
                    _buildSectionHeader(
                      icon: Icons.security_rounded,
                      title: 'Security & Driver Authentication',
                    ),
                    _buildSettingsContainer([
                      InkWell(
                        onTap: _showChangePasswordBottomSheet,
                        borderRadius: BorderRadius.circular(6.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Change App Password',
                                      style: TextStyle(
                                        color: slate900,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _passwordSubtitle,
                                      style: const TextStyle(
                                        color: slate500,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: slate400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    // Section 3: Account & Session
                    _buildSectionHeader(
                      icon: Icons.account_circle_outlined,
                      title: 'Account & Session',
                    ),
                    _buildSettingsContainer([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: slate100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.badge_outlined,
                                size: 18,
                                color: slate600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverName.isNotEmpty
                                        ? 'Signed in as $_driverName'
                                        : 'Logged in as',
                                    style: const TextStyle(
                                      color: slate500,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayEmail,
                                    style: const TextStyle(
                                      color: slate900,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: emerald50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: emerald200),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: emerald600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: emerald600,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: slate100, height: 1),
                      InkWell(
                        onTap: () => LogoutHelper.showLogoutDialog(context),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(6.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Log Out of CarrierDirect',
                                      style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'End driver session on this device',
                                      style: TextStyle(
                                        color: slate500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // App Version Info
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'CarrierDirect Driver App v2.4.12 (Build 8940)',
                            style: TextStyle(
                              color: slate400,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'FMCSA ELD Certified & Compliance Ready',
                            style: TextStyle(
                              color: slate400.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryOrange),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: slate900,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
