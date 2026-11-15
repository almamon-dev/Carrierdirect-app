import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../services/google_navigation_service.dart';
import '../../../../services/order_gps_tracker_service.dart';
import '../../../chat/presentation/screens/chat_inbox_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../onboarding/presentation/widgets/document_verification_modal.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../trips/presentation/screens/in_app_navigation_screen.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../../trips/presentation/screens/shipment_details_screen.dart';
import '../../../trips/presentation/screens/trips_screen.dart';
import '../../../../shared/widgets/app_bottom_navigation.dart';
import '../../../../shared/widgets/section_header.dart';

import 'package:google_fonts/google_fonts.dart';

import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isOnline = true;
  bool _isComplianceVerified = false; // Driver Compliance Status
  int _unreadNotificationCount = 0;
  String _headerDriverName = '';
  String? _headerAvatarUrl;
  Timer? _notificationPollerTimer;
  DashboardStatsModel? _dashboardStats;
  List<ShipmentItem> _allDashboardShipments = [];
  int _selectedDateTabIndex = 0; // 0 = Today, 1 = Tomorrow, 2 = Upcoming
  String? _expandedOrderId;
  bool _isLoadingDashboard = true;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  static const Color primaryColor = AppColors.primary;

  String? _cachedAuthToken;

  Future<String?> _getAuthToken() async {
    if (_cachedAuthToken != null && _cachedAuthToken!.isNotEmpty) {
      return _cachedAuthToken;
    }
    _cachedAuthToken = await SecureStorage().read(AppConstants.keyAuthToken);
    return _cachedAuthToken;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isBeforeDay(DateTime a, DateTime b) {
    final dayA = DateTime(a.year, a.month, a.day);
    final dayB = DateTime(b.year, b.month, b.day);
    return dayA.isBefore(dayB);
  }

  static bool _isAfterDay(DateTime a, DateTime b) {
    final dayA = DateTime(a.year, a.month, a.day);
    final dayB = DateTime(b.year, b.month, b.day);
    return dayA.isAfter(dayB);
  }

  DateTime? _parseShipmentDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == '—' || dateStr.toLowerCase() == 'null') {
      return null;
    }
    final raw = dateStr.trim();

    // 1. Direct ISO 8601 parsing (e.g. 2026-11-08 or 2026-11-08T10:30:00Z)
    final tryDirect = DateTime.tryParse(raw);
    if (tryDirect != null) {
      return DateTime(tryDirect.year, tryDirect.month, tryDirect.day);
    }

    // 2. Formats with month names: "08 Nov 2026", "Nov 08, 2026", "08-Nov-2026", "8 November 2026"
    final sanitized = raw
        .replaceAll(',', ' ')
        .replaceAll('-', ' ')
        .replaceAll('/', ' ')
        .trim();
    final parts = sanitized.split(RegExp(r'\s+'));
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    if (parts.length >= 3) {
      // e.g. "08" "Nov" "2026"
      final dayCandidate = int.tryParse(parts[0]);
      final monthCandidateStr = parts[1].toLowerCase();
      final yearCandidate = int.tryParse(parts[2]);
      if (dayCandidate != null && yearCandidate != null) {
        final month = months.entries
            .firstWhere(
              (e) => monthCandidateStr.startsWith(e.key),
              orElse: () => const MapEntry('', 0),
            )
            .value;
        if (month > 0 &&
            dayCandidate >= 1 &&
            dayCandidate <= 31 &&
            yearCandidate > 2000) {
          return DateTime(yearCandidate, month, dayCandidate);
        }
      }

      // e.g. "Nov" "08" "2026"
      final monthCandidateStr2 = parts[0].toLowerCase();
      final dayCandidate2 = int.tryParse(parts[1]);
      final yearCandidate2 = int.tryParse(parts[2]);
      if (dayCandidate2 != null && yearCandidate2 != null) {
        final month = months.entries
            .firstWhere(
              (e) => monthCandidateStr2.startsWith(e.key),
              orElse: () => const MapEntry('', 0),
            )
            .value;
        if (month > 0 &&
            dayCandidate2 >= 1 &&
            dayCandidate2 <= 31 &&
            yearCandidate2 > 2000) {
          return DateTime(yearCandidate2, month, dayCandidate2);
        }
      }

      // e.g. "2026" "Nov" "08"
      final yearCandidate3 = int.tryParse(parts[0]);
      final monthCandidateStr3 = parts[1].toLowerCase();
      final dayCandidate3 = int.tryParse(parts[2]);
      if (yearCandidate3 != null &&
          dayCandidate3 != null &&
          yearCandidate3 > 2000) {
        final month = months.entries
            .firstWhere(
              (e) => monthCandidateStr3.startsWith(e.key),
              orElse: () => const MapEntry('', 0),
            )
            .value;
        if (month > 0 && dayCandidate3 >= 1 && dayCandidate3 <= 31) {
          return DateTime(yearCandidate3, month, dayCandidate3);
        }
      }
    }

    // 3. Numeric formats: "08/11/2026" or "2026/11/08" or "08-11-2026"
    if (raw.contains('/') || raw.contains('-')) {
      final sep = raw.contains('/') ? '/' : '-';
      final tokens = raw.split(sep);
      if (tokens.length == 3) {
        final first = int.tryParse(tokens[0]);
        final second = int.tryParse(tokens[1]);
        final third = int.tryParse(tokens[2]);
        if (first != null && second != null && third != null) {
          if (first > 1000) {
            // YYYY-MM-DD
            return DateTime(first, second, third);
          } else if (third > 1000) {
            // DD/MM/YYYY
            return DateTime(third, second, first);
          }
        }
      }
    }

    // 4. Relative words (strictly as fallback when no calendar date is present)
    final clean = raw.toLowerCase();
    final now = DateTime.now();
    if (clean == 'today' || clean.startsWith('today')) {
      return DateTime(now.year, now.month, now.day);
    }
    if (clean == 'tomorrow' || clean.startsWith('tomorrow')) {
      final tom = now.add(const Duration(days: 1));
      return DateTime(tom.year, tom.month, tom.day);
    }
    if (clean == 'yesterday' || clean.startsWith('yesterday')) {
      final yest = now.subtract(const Duration(days: 1));
      return DateTime(yest.year, yest.month, yest.day);
    }

    return null;
  }

  DateTime? _getEffectiveDate(ShipmentItem item) {
    // 1. Pickup date is the primary operational date of the shipment
    if (item.pickupDate.isNotEmpty &&
        item.pickupDate != '—' &&
        item.pickupDate.toLowerCase() != 'null') {
      final d = _parseShipmentDate(item.pickupDate);
      if (d != null) return d;
    }
    // 2. Delivery date as second candidate
    if (item.deliveryDate.isNotEmpty &&
        item.deliveryDate != '—' &&
        item.deliveryDate.toLowerCase() != 'null') {
      final d = _parseShipmentDate(item.deliveryDate);
      if (d != null) return d;
    }
    // 3. Fallback to shipment's date field
    if (item.date.isNotEmpty &&
        item.date != '—' &&
        item.date.toLowerCase() != 'null') {
      final d = _parseShipmentDate(item.date);
      if (d != null) return d;
    }
    return null;
  }

  List<ShipmentItem> get _todayOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allDashboardShipments.where((item) {
      final d = _getEffectiveDate(item);

      // If a real calendar date exists:
      if (d != null) {
        // If it's strictly a previous day, NEVER include in Today!
        if (_isBeforeDay(d, today)) return false;
        // If it's tomorrow or future, NEVER include in Today!
        if (_isAfterDay(d, today)) return false;
        // Must be exactly today!
        return _isSameDay(d, today);
      }

      // If no calendar date could be parsed:
      final str = '${item.pickupDate} ${item.date}'.toLowerCase();
      if (str.contains('today')) return true;
      if (str.contains('yesterday') || str.contains('tomorrow')) return false;

      return false;
    }).toList();
  }

  List<ShipmentItem> get _tomorrowOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _allDashboardShipments.where((item) {
      final d = _getEffectiveDate(item);

      if (d != null) {
        return _isSameDay(d, tomorrow);
      }

      final str = '${item.pickupDate} ${item.date}'.toLowerCase();
      if (str.contains('tomorrow')) return true;
      return false;
    }).toList();
  }

  List<ShipmentItem> get _upcomingOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _allDashboardShipments.where((item) {
      // Completed or cancelled orders belong in history, not upcoming
      if (item.status == ShipmentFilter.completed ||
          item.status == ShipmentFilter.cancelled) {
        return false;
      }

      final d = _getEffectiveDate(item);

      // If a real calendar date exists:
      if (d != null) {
        // If it's today or tomorrow, it belongs in Today or Tomorrow tab
        if (_isSameDay(d, today) || _isSameDay(d, tomorrow)) {
          return false;
        }
        // Future dates or open/active shipments belong in Upcoming!
        return true;
      }

      // If no calendar date could be parsed:
      final str = '${item.pickupDate} ${item.date}'.toLowerCase();
      if (str.contains('today') || str.contains('tomorrow')) {
        return false;
      }

      // All other active, scheduled, or pending shipments belong in Upcoming!
      return true;
    }).toList();
  }

  List<ShipmentItem> get _currentTabOrders {
    switch (_selectedDateTabIndex) {
      case 0:
        return _todayOrders;
      case 1:
        return _tomorrowOrders;
      case 2:
        return _upcomingOrders;
      default:
        return _todayOrders;
    }
  }

  String get _selectedTabTitle {
    switch (_selectedDateTabIndex) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      case 2:
        return 'Upcoming';
      default:
        return 'Today';
    }
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    // Enforce dark status bar icons (time, battery, wifi, network) on light theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Check Driver Verification Gatekeeper on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkComplianceGate();
      _fetchDashboardOverview();
      _fetchUnreadNotificationCount();
      _startBackgroundNotificationPoller();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _notificationPollerTimer?.cancel();
    super.dispose();
  }

  void _startBackgroundNotificationPoller() {
    _notificationPollerTimer?.cancel();
    // 60-second gentle poll to avoid lag and continuous frame invalidation
    _notificationPollerTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && _currentIndex == 0) {
        _fetchUnreadNotificationCount();
      }
    });
  }

  Future<void> _fetchDashboardOverview({bool silent = false}) async {
    if (!silent) {
      if (mounted) {
        setState(() => _isLoadingDashboard = true);
        if (!_shimmerController.isAnimating) {
          _shimmerController.repeat();
        }
      }
    }
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

      final dashUri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverDashboard}',
      );
      final shipmentsUri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverShipments}',
      );

      // Concurrently fetch dashboard overview and full shipment list
      final responses = await Future.wait([
        http
            .get(dashUri, headers: headers)
            .timeout(const Duration(seconds: 12))
            .then<http.Response?>((r) => r)
            .catchError((e) {
          debugPrint('Dashboard API error: $e');
          return null;
        }),
        http
            .get(shipmentsUri, headers: headers)
            .timeout(const Duration(seconds: 12))
            .then<http.Response?>((r) => r)
            .catchError((e) {
          debugPrint('Shipments API error: $e');
          return null;
        }),
      ]);

      final dashRes = responses[0];
      final shipRes = responses[1];

      DashboardStatsModel? stats;
      final List<ShipmentItem> allCombined = [];

      // Parse Dashboard Metrics & Schedules
      if (dashRes != null && dashRes.statusCode == 200) {
        final dynamic body = jsonDecode(dashRes.body);
        if (body is Map<String, dynamic> &&
            body['data'] is Map<String, dynamic>) {
          final data = body['data'] as Map<String, dynamic>;

          if (data['metrics'] is Map<String, dynamic>) {
            stats = DashboardStatsModel.fromJson(
              data['metrics'] as Map<String, dynamic>,
            );
          } else if (data['stats'] is Map<String, dynamic>) {
            stats = DashboardStatsModel.fromJson(
              data['stats'] as Map<String, dynamic>,
            );
          } else {
            stats = DashboardStatsModel.fromJson(data);
          }

          if (data['today_schedule'] is List) {
            for (final item in data['today_schedule']) {
              if (item is Map<String, dynamic>) {
                final s = ShipmentItem.fromJson(item);
                if (!allCombined.any((x) => x.id == s.id)) {
                  allCombined.add(s);
                }
              }
            }
          }

          if (data['recent_trips'] is List) {
            for (final item in data['recent_trips']) {
              if (item is Map<String, dynamic>) {
                final s = ShipmentItem.fromJson(item);
                if (!allCombined.any((x) => x.id == s.id)) {
                  allCombined.add(s);
                }
              }
            }
          }
        }
      }

      // Parse Full Shipments List (used by My Shipments screen for Tomorrow, Upcoming & all workload)
      if (shipRes != null && shipRes.statusCode == 200) {
        final dynamic sBody = jsonDecode(shipRes.body);
        List? rawList;
        if (sBody is Map<String, dynamic>) {
          final d = sBody['data'];
          if (d is Map<String, dynamic> && d['shipments'] is List) {
            rawList = d['shipments'] as List;
          } else if (d is List) {
            rawList = d;
          } else if (sBody['shipments'] is List) {
            rawList = sBody['shipments'] as List;
          }
        } else if (sBody is List) {
          rawList = sBody;
        }

        if (rawList != null) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              final sItem = ShipmentItem.fromJson(item);
              if (!allCombined.any((x) => x.id == sItem.id)) {
                allCombined.add(sItem);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          if (stats != null) _dashboardStats = stats;
          _allDashboardShipments = allCombined;
          _isLoadingDashboard = false;
        });
        _shimmerController.stop();
        OrderGpsTrackerService().recoverActiveShipmentTracking(allCombined);
      }

      // Background enrichment with Google Maps routes
      try {
        final enrichedList = await GoogleNavigationService()
            .enrichShipmentList(allCombined);
        if (mounted && enrichedList.isNotEmpty) {
          setState(() {
            _allDashboardShipments = enrichedList;
          });
        }
      } catch (_) {}
      return;
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      if (mounted && _isLoadingDashboard) {
        setState(() => _isLoadingDashboard = false);
        _shimmerController.stop();
      }
    }
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverNotifications}',
      );
      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        int unread = 0;

        if (body is Map<String, dynamic>) {
          // 1. Root level unread_count / unread
          if (body['unread_count'] != null) {
            unread = int.tryParse(body['unread_count'].toString()) ?? 0;
          } else if (body['unread'] != null) {
            unread = int.tryParse(body['unread'].toString()) ?? 0;
          }

          // 2. data map level
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            if (data['unread_count'] != null) {
              unread = int.tryParse(data['unread_count'].toString()) ?? unread;
            } else if (data['unread'] != null) {
              unread = int.tryParse(data['unread'].toString()) ?? unread;
            } else if (data['notifications'] is List) {
              final list = data['notifications'] as List;
              int count = 0;
              for (final item in list) {
                if (item is Map) {
                  final isRead =
                      item['is_read'] == true ||
                      item['is_read'] == 1 ||
                      item['read_at'] != null;
                  if (!isRead) count++;
                }
              }
              if (unread == 0 && count > 0) unread = count;
            }
          } else if (data is List) {
            // data is directly a list of notifications
            int count = 0;
            for (final item in data) {
              if (item is Map) {
                final isRead =
                    item['is_read'] == true ||
                    item['is_read'] == 1 ||
                    item['read_at'] != null;
                if (!isRead) count++;
              }
            }
            if (unread == 0 && count > 0) unread = count;
          }
        }

        if (mounted) {
          final previousCount = _unreadNotificationCount;
          setState(() {
            _unreadNotificationCount = unread;
          });

          // Live dashboard sync when a new notification arrives
          if (unread > previousCount && previousCount > 0) {
            _fetchDashboardOverview(silent: true);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _checkComplianceGate() async {
    try {
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.driverProfile}',
        );
        final res = await http
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'ngrok-skip-browser-warning': 'true',
              },
            )
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data =
              jsonDecode(res.body)['data'] as Map<String, dynamic>? ?? {};
          final verificationMap =
              data['verification'] as Map<String, dynamic>? ?? {};
          final isVerified =
              data['is_verified'] == true ||
              verificationMap['is_verified'] == true;
          final status =
              (data['verification_status'] ?? verificationMap['status'] ?? '')
                  .toString()
                  .toLowerCase();

          if (!isVerified || (status != 'verified' && status != 'approved')) {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminApproval,
                (route) => false,
              );
              return;
            }
          } else {
            if (mounted) {
              setState(() {
                _isComplianceVerified = true;
                if (data['name'] != null) {
                  _headerDriverName = data['name'].toString();
                }
                if (data['profile_picture'] != null) {
                  _headerAvatarUrl = data['profile_picture'].toString();
                }
              });
            }
            return;
          }
        }
      }
    } catch (_) {}

    if (!_isComplianceVerified && mounted) {
      _openVerificationModal();
    }
  }

  void _openVerificationModal() {
    DocumentVerificationModal.show(
      context,
      onVerificationComplete: () {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.adminApproval, (route) => false);
        }
      },
    );
  }

  void _handleTabTap(int index) {
    // If not verified and trying to access Shipments (1), Live Chat (2), or Notifications (3)
    if (!_isComplianceVerified && (index == 1 || index == 2 || index == 3)) {
      _showAccessDeniedModal(index);
    } else {
      final prevIndex = _currentIndex;
      setState(() {
        _currentIndex = index;
      });
      _fetchUnreadNotificationCount();
      // If switching back to dashboard from another tab and shipments list was empty, re-fetch!
      if (index == 0 && (prevIndex != 0 || _allDashboardShipments.isEmpty)) {
        _fetchDashboardOverview(silent: true);
      }
    }
  }

  // Gatekeeper Bottom Sheet Modal when clicking locked tabs
  void _showAccessDeniedModal(int targetIndex) {
    String tabName = 'Shipments & Loads';
    if (targetIndex == 1) {
      tabName = 'Shipments & Loads';
    } else if (targetIndex == 2) {
      tabName = 'Live Dispatch & Customer Chat';
    } else if (targetIndex == 3) {
      tabName = 'Dispatch Notifications';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Color(0xFFD97706),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Driver Verification Required',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You must complete your mandatory compliance verification (Govt ID, CDL License & Medical Card) to access $tabName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openVerificationModal();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Complete Verification (3 Steps)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardHome(),
      const TripsScreen(showBackButton: false),
      const ChatInboxScreen(),
      const NotificationsScreen(),
      const ProfileScreen(showBackButton: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex >= screens.length ? 0 : _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex >= screens.length ? 0 : _currentIndex,
        onTap: _handleTabTap,
        unreadNotifications: _unreadNotificationCount,
      ),
    );
  }

  Widget _buildDashboardHome() {
    final currentOrders = _currentTabOrders;
    final tabTitle = _selectedTabTitle;
    final firstOrderId = currentOrders.isNotEmpty
        ? currentOrders.first.id
        : null;
    final effectiveExpandedId = _expandedOrderId ?? firstOrderId;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _fetchDashboardOverview(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row (Driver Avatar, Greeting, Online Toggle & Chat/Notification icons)
              _buildTopHeader(),
              const SizedBox(height: 14),

              // 2. Activity Summary (4 Stat Cards in 2x2 Grid)
              const SectionHeader(title: "Activity Summary"),
              const SizedBox(height: 8),
              if (_isLoadingDashboard || _dashboardStats == null)
                _buildStatCardsSkeleton()
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "Active Loads",
                        value: "${_dashboardStats?.activeLoads ?? 0} Loads",
                        icon: Icons.inventory_2_outlined,
                        iconColor: AppColors.primary,
                        iconBgColor: AppColors.primaryLight,
                        subtitle: "In dispatch transit",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: "Trips Completed",
                        value: "${_dashboardStats?.completedTrips ?? 0} Orders",
                        icon: Icons.local_shipping_rounded,
                        iconColor: AppColors.success,
                        iconBgColor: AppColors.successLight,
                        subtitle: "Delivered",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "Distance",
                        value:
                            "${(_dashboardStats?.totalDistanceKm ?? 0.0).toStringAsFixed(1)} km",
                        icon: Icons.route_rounded,
                        iconColor: AppColors.info,
                        iconBgColor: AppColors.infoLight,
                        subtitle: "Total route",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: "Driver Rating",
                        value:
                            "${(_dashboardStats?.rating ?? 0.0).toStringAsFixed(1)} ★",
                        icon: Icons.star_rounded,
                        iconColor: AppColors.warning,
                        iconBgColor: AppColors.warningLight,
                        subtitle: "Fleet rating",
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // 3. Date Selection Tabs (Today, Tomorrow, Upcoming)
              Row(
                children: [
                  _buildDateTab(
                    index: 0,
                    label: 'Today',
                    count: _todayOrders.length,
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildDateTab(
                    index: 1,
                    label: 'Tomorrow',
                    count: _tomorrowOrders.length,
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildDateTab(
                    index: 2,
                    label: 'Upcoming',
                    count: _upcomingOrders.length,
                    icon: Icons.layers_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Section Header: My Tasks  --  View All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _handleTabTap(1); // Switch to Shipments tab
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Orders List
              if (_isLoadingDashboard)
                _buildShipmentSkeletonCard()
              else if (currentOrders.isEmpty)
                _buildEmptyOrdersState(tabTitle)
              else
                ...currentOrders.map((item) {
                  final isExpanded = item.id == effectiveExpandedId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: isExpanded
                        ? _buildExpandedOrderCard(item)
                        : _buildCompactOrderCard(item),
                  );
                }),

              // 6. Footer: Showing X of X tasks for today
              if (!_isLoadingDashboard && currentOrders.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Text(
                      'Showing ${currentOrders.length} of ${currentOrders.length} tasks for ${tabTitle.toLowerCase()}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Avatar + Greeting & Name
        Expanded(
          child: GestureDetector(
            onTap: () => _handleTabTap(4),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child:
                            (_headerAvatarUrl != null &&
                                _headerAvatarUrl!.isNotEmpty)
                            ? Image.network(
                                _headerAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/driver_avatar.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/driver_avatar.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back,',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _headerDriverName.isNotEmpty
                            ? '$_headerDriverName 👋'
                            : 'Billy Smith 👋',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Status Pill, Live Chat Icon, Notification Bell
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Pill Toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  _isOnline = !_isOnline;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5.5,
                ),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnline
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _isOnline
                            ? const Color(0xFF065F46)
                            : const Color(0xFF475569),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Live Chat Button
            GestureDetector(
              onTap: () {
                _handleTabTap(2); // Switch to Live Chat Tab
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF334155),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Notification Bell Icon with Badge
            GestureDetector(
              onTap: () {
                _handleTabTap(3); // Switch to Notifications Tab
                _fetchUnreadNotificationCount();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              _unreadNotificationCount > 9
                                  ? '9+'
                                  : '$_unreadNotificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTab({
    required int index,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedDateTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDateTabIndex = index;
            _expandedOrderId = null; // reset to first in selected tab
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5722) : Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF5722)
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.22),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$label ($count)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusBadge(ShipmentItem item) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (item.status) {
      case ShipmentFilter.inProgress:
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF0284C7);
        icon = Icons.local_shipping_outlined;
        label = item.statusLabel.isNotEmpty ? item.statusLabel : 'Picked up';
        break;
      case ShipmentFilter.completed:
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        text = const Color(0xFF059669);
        icon = Icons.check_circle_outline_rounded;
        label = 'Delivered';
        break;
      case ShipmentFilter.cancelled:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        label = 'Cancelled';
        break;
      case ShipmentFilter.scheduled:
      default:
        bg = const Color(0xFFFFF7ED);
        border = const Color(0xFFFED7AA);
        text = const Color(0xFFEA580C);
        icon = Icons.local_shipping_outlined;
        label = item.statusLabel.isNotEmpty ? item.statusLabel : 'Pickup';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        final val = _shimmerAnimation.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: borderRadius ?? BorderRadius.circular(4.0),
            gradient: LinearGradient(
              begin: Alignment(val - 1.0, 0),
              end: Alignment(val + 1.0, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCardsSkeleton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCardSkeleton()),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCardSkeleton()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCardSkeleton()),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCardSkeleton()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 65, height: 12),
              _buildShimmerBox(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildShimmerBox(width: 80, height: 18),
              const SizedBox(height: 3),
              _buildShimmerBox(width: 55, height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 140, height: 16),
              _buildShimmerBox(
                width: 75,
                height: 20,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildShimmerBox(width: 120, height: 12),
          const SizedBox(height: 12),
          _buildShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _buildShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildShimmerBox(
                  width: double.infinity,
                  height: 38,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildShimmerBox(
                  width: double.infinity,
                  height: 38,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedOrderCard(ShipmentItem shipment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFFEA580C),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${shipment.id}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              _buildOrderStatusBadge(shipment),
            ],
          ),
          const SizedBox(height: 8),

          // Date & Time subtitle
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                _formatSchedule(
                  shipment.deliveryDate.isNotEmpty &&
                          shipment.deliveryDate != '—'
                      ? shipment.deliveryDate
                      : shipment.date,
                  shipment.deliveryTime.isNotEmpty &&
                          shipment.deliveryTime != '—'
                      ? shipment.deliveryTime
                      : shipment.time,
                ),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Origin block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.0),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF16A34A),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shipment.originTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (shipment.pickupDate.isNotEmpty &&
                            shipment.pickupDate != '—')
                          Text(
                            '${shipment.pickupDate} • ${shipment.pickupTime.isNotEmpty && shipment.pickupTime != '—' ? shipment.pickupTime : '09:00 AM'}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shipment.originAddress,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Connector line
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
            child: Container(
              height: 14,
              width: 1.5,
              color: const Color(0xFFE2E8F0),
            ),
          ),

          // Destination block
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.0),
                child: Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFDC2626),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shipment.destTitle,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (shipment.deliveryDate.isNotEmpty &&
                            shipment.deliveryDate != '—')
                          Text(
                            '${shipment.deliveryDate} • ${shipment.deliveryTime.isNotEmpty && shipment.deliveryTime != '—' ? shipment.deliveryTime : '05:00 PM'}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shipment.destAddress,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metadata row: Distance, Pallets, Weight
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.alt_route_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shipment.formattedDistance,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shipment.palletQuantity,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shipment.payloadWeight,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons: [▲ Navigation] and [Details]
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              InAppNavigationScreen(shipment: shipment),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.navigation_rounded,
                      size: 13.5,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Navigation',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ShipmentDetailsScreen(shipment: shipment),
                        ),
                      );
                      if (mounted) {
                        _fetchDashboardOverview();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOrderCard(ShipmentItem shipment) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedOrderId = shipment.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFFEA580C),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${shipment.id}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                _buildOrderStatusBadge(shipment),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 11.5,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatSchedule(
                    shipment.deliveryDate.isNotEmpty &&
                            shipment.deliveryDate != '—'
                        ? shipment.deliveryDate
                        : shipment.date,
                    shipment.deliveryTime.isNotEmpty &&
                            shipment.deliveryTime != '—'
                        ? shipment.deliveryTime
                        : shipment.time,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersState(String tabTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 26,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Tasks for $tabTitle',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No dispatch tasks scheduled for ${tabTitle.toLowerCase()}.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSchedule(String rawDate, String rawTime) {
    final cleanDate = rawDate.trim();
    String cleanTime = rawTime.trim();

    if (cleanTime.isNotEmpty && cleanTime != '—') {
      final timeRangeRegex = RegExp(
        r'(\d{1,2}:\d{2})\s*(AM|PM)?\s*-\s*(\d{1,2}:\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = timeRangeRegex.firstMatch(cleanTime);
      if (match != null) {
        final startH = match.group(1);
        final startM = match.group(2)?.toUpperCase();
        final endH = match.group(3);
        final endM = match.group(4)?.toUpperCase();

        if (startM != null && startM == endM) {
          cleanTime = '$startH - $endH $endM';
        } else if (startM != null && endM != null) {
          cleanTime = '$startH $startM - $endH $endM';
        }
      }
    }

    final hasDate = cleanDate.isNotEmpty && cleanDate != '—';
    final hasTime = cleanTime.isNotEmpty && cleanTime != '—';

    if (hasDate && hasTime) {
      return '$cleanDate • $cleanTime';
    } else if (hasDate) {
      return cleanDate;
    } else if (hasTime) {
      return cleanTime;
    }
    return 'Scheduled';
  }
}
