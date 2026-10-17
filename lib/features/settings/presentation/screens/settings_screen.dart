import 'package:flutter/material.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/logout_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _loadAlerts = true;
  bool _soundAndVibration = true;
  bool _biometricLock = true;
  bool _twoFactorAuth = true;
  // Smart Routing & Navigation State
  bool _bestRouteOptimization = true;
  bool _truckSafeRouting = true;
  bool _dynamicRerouting = true;
  bool _avoidTolls = false;
  String _routePreference = 'Fastest & Safest (Recommended)';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slate50,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar matching ProfileScreen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  const Text(
                    'App Settings & Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Body
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: [
                  // Section 1: Notifications
                  _buildSectionHeader(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications & Dispatch Alerts',
                  ),
                  _buildSettingsContainer([
                    _buildSwitch(
                      title: 'Push Notifications',
                      subtitle: 'Receive instant alerts for newly assigned loads',
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    _buildSwitch(
                      title: 'High-Priority Dispatch Alerts',
                      subtitle: 'Loud chime for urgent route changes and re-routes',
                      value: _loadAlerts,
                      onChanged: (val) => setState(() => _loadAlerts = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    _buildSwitch(
                      title: 'Sound & Vibration',
                      subtitle: 'Haptic feedback on scan and route checkpoints',
                      value: _soundAndVibration,
                      onChanged: (val) => setState(() => _soundAndVibration = val),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // Section 2: Security & Biometrics
                  _buildSectionHeader(
                    icon: Icons.security_rounded,
                    title: 'Security & Driver Authentication',
                  ),
                  _buildSettingsContainer([
                    _buildSwitch(
                      title: 'Biometric Lock (Face ID / Fingerprint)',
                      subtitle: 'Require biometrics when opening the app',
                      value: _biometricLock,
                      onChanged: (val) => setState(() => _biometricLock = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    _buildSwitch(
                      title: 'Two-Factor Authentication (2FA)',
                      subtitle: 'SMS verification code on new device login',
                      value: _twoFactorAuth,
                      onChanged: (val) => setState(() => _twoFactorAuth = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    InkWell(
                      onTap: () {
                        AppToast.info(context, 'Password reset instructions sent to registered email.');
                      },
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6.0)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change App Password',
                                  style: TextStyle(
                                    color: slate900,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Last updated 45 days ago',
                                  style: TextStyle(
                                    color: slate500,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.chevron_right_rounded, size: 20, color: slate400),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // Section 3: Smart Route & Navigation Engine
                  _buildSectionHeader(
                    icon: Icons.alt_route_rounded,
                    title: 'Smart Route & Navigation Engine',
                  ),
                  _buildSettingsContainer([
                    _buildSwitch(
                      title: 'AI Best Route Optimization',
                      subtitle: 'Auto-selects the fastest & safest route using live traffic',
                      value: _bestRouteOptimization,
                      onChanged: (val) => setState(() => _bestRouteOptimization = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    _buildSwitch(
                      title: 'Commercial Truck-Safe Route',
                      subtitle: 'Avoids low bridges, weight limits & hazardous cargo zones',
                      value: _truckSafeRouting,
                      onChanged: (val) => setState(() => _truckSafeRouting = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    _buildSwitch(
                      title: 'Faster Alternative Route Alerts',
                      subtitle: 'Automatically re-routes when alternative saves >5 mins',
                      value: _dynamicRerouting,
                      onChanged: (val) => setState(() => _dynamicRerouting = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    _buildSwitch(
                      title: 'Avoid Toll Roads & Expressways',
                      subtitle: 'Prefers free highways and non-toll alternatives',
                      value: _avoidTolls,
                      onChanged: (val) => setState(() => _avoidTolls = val),
                    ),
                    const Divider(color: slate100, height: 1),
                    InkWell(
                      onTap: _showRoutePreferenceDialog,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6.0)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Route Preference Mode',
                                  style: TextStyle(
                                    color: slate900,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _routePreference,
                                  style: const TextStyle(
                                    color: primaryOrange,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20, color: slate400),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // Section 4: Session & Account
                  _buildSectionHeader(
                    icon: Icons.account_circle_outlined,
                    title: 'Account & Session',
                  ),
                  _buildSettingsContainer([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.badge_outlined, size: 18, color: slate600),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Logged in as',
                                  style: TextStyle(color: slate500, fontSize: 11),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'amon193p@gmail.com',
                                  style: TextStyle(
                                    color: slate900,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
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
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6.0)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                    style: TextStyle(color: slate500, fontSize: 11),
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
                          style: TextStyle(color: slate400, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'FMCSA ELD Certified & Compliance Ready',
                          style: TextStyle(color: slate400.withValues(alpha: 0.8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: slate900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: slate500,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: primaryOrange,
            activeTrackColor: primaryOrange.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: slate200,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showRoutePreferenceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icon(Icons.alt_route_rounded, color: primaryOrange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Choose Best Route Mode',
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
                  'Select how our smart routing engine calculates the best path for your trips.',
                  style: TextStyle(color: slate500, fontSize: 12),
                ),
                const SizedBox(height: 14),
                _buildRouteOptionTile(
                  title: 'Fastest & Safest (Recommended)',
                  subtitle: 'Real-time traffic avoidance, minimal delay & high-speed bypasses',
                  icon: Icons.bolt_rounded,
                  ctx: ctx,
                ),
                const SizedBox(height: 8),
                _buildRouteOptionTile(
                  title: 'Fuel-Efficient (Eco Route)',
                  subtitle: 'Flattest terrain and consistent highway speeds to minimize fuel',
                  icon: Icons.eco_outlined,
                  ctx: ctx,
                ),
                const SizedBox(height: 8),
                _buildRouteOptionTile(
                  title: 'Heavy Cargo Corridor Priority',
                  subtitle: 'Restricted to wide multi-lane interstate and designated truck routes',
                  icon: Icons.local_shipping_outlined,
                  ctx: ctx,
                ),
                const SizedBox(height: 8),
                _buildRouteOptionTile(
                  title: 'Shortest Distance',
                  subtitle: 'Direct point-to-point path with fewest kilometers',
                  icon: Icons.straighten_rounded,
                  ctx: ctx,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required BuildContext ctx,
  }) {
    final isSelected = _routePreference == title;
    return InkWell(
      onTap: () {
        setState(() => _routePreference = title);
        Navigator.pop(ctx);
        AppToast.success(context, 'Route mode updated: $title');
      },
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : slate50,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected ? primaryOrange : slate200,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? primaryOrange.withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(icon, color: isSelected ? primaryOrange : slate600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? slate900 : slate800,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: slate500, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: primaryOrange, size: 20),
          ],
        ),
      ),
    );
  }
}

