import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/coming_soon_modal.dart';
import 'shipment_details_screen.dart';
import 'in_app_navigation_screen.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../services/google_navigation_service.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/loading_state.dart';
import '../../../../shared/widgets/empty_state.dart';

import '../../data/models/shipment_item_model.dart';
export '../../data/models/shipment_item_model.dart';


class TripsScreen extends StatefulWidget {
  final bool showBackButton;
  const TripsScreen({super.key, this.showBackButton = false});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  ShipmentFilter _selectedFilter = ShipmentFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Advanced Filter States
  String _selectedDatePreset =
      'All'; // 'All', 'Today', 'Tomorrow', 'This Week', 'Custom'
  DateTimeRange? _customDateRange;
  String _selectedTimeWindow = 'All'; // 'All', 'Morning (6 AM - 12 PM)', 'Afternoon (12 PM - 5 PM)', 'Evening (5 PM - 6 AM)'
  String _selectedCargoType = 'All';
  String _selectedSortBy =
      'default'; // 'default', 'earliest', 'shortestDist', 'longestDist'

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = AppColors.background;

  bool _isLoading = true;
  List<ShipmentItem> _shipments = [];

  int get _activeAdvancedFilterCount {
    int count = 0;
    if (_selectedDatePreset != 'All') count++;
    if (_selectedTimeWindow != 'All') count++;
    if (_selectedCargoType != 'All') count++;
    if (_selectedSortBy != 'default') count++;
    return count;
  }

  Set<String> get _availableCargoTypes {
    final types = <String>{'All'};
    for (final s in _shipments) {
      if (s.cargoType.trim().isNotEmpty && s.cargoType.trim() != '—') {
        types.add(s.cargoType.trim());
      }
      if (s.equipmentType.trim().isNotEmpty && s.equipmentType.trim() != '—') {
        types.add(s.equipmentType.trim());
      }
      if (s.serviceType.trim().isNotEmpty && s.serviceType.trim() != '—') {
        types.add(s.serviceType.trim());
      }
    }
    return types;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
            return DateTime(first, second, third);
          } else if (third > 1000) {
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
    if (item.pickupDate.isNotEmpty &&
        item.pickupDate != '—' &&
        item.pickupDate.toLowerCase() != 'null') {
      final d = _parseShipmentDate(item.pickupDate);
      if (d != null) return d;
    }
    if (item.deliveryDate.isNotEmpty &&
        item.deliveryDate != '—' &&
        item.deliveryDate.toLowerCase() != 'null') {
      final d = _parseShipmentDate(item.deliveryDate);
      if (d != null) return d;
    }
    if (item.date.isNotEmpty &&
        item.date != '—' &&
        item.date.toLowerCase() != 'null') {
      final d = _parseShipmentDate(item.date);
      if (d != null) return d;
    }
    return null;
  }

  List<int> _parseShipmentHours(ShipmentItem item) {
    final timeCandidates = [item.pickupTime, item.time, item.deliveryTime];
    final hours = <int>[];
    final reg = RegExp(r'(\d{1,2}):(\d{2})(?:\s*([APap][Mm]))?');

    for (final timeStr in timeCandidates) {
      if (timeStr.isEmpty || timeStr == '—' || timeStr.toLowerCase() == 'null') {
        continue;
      }
      final matches = reg.allMatches(timeStr);
      for (final match in matches) {
        int hour = int.tryParse(match.group(1)!) ?? 0;
        final ampm = match.group(3)?.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        if (!hours.contains(hour)) {
          hours.add(hour);
        }
      }
    }
    return hours;
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _fetchShipments();
  }

  Future<void> _fetchShipments() async {
    try {
      final token = await SecureStorage().read(AppConstants.keyAuthToken);
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.driverShipments}',
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
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        if (body is Map<String, dynamic> &&
            body['data'] is Map<String, dynamic>) {
          final data = body['data'] as Map<String, dynamic>;
          final List<ShipmentItem> loaded = [];

          if (data['shipments'] is List) {
            for (final s in data['shipments']) {
              if (s is Map<String, dynamic>) {
                loaded.add(ShipmentItem.fromJson(s));
              }
            }
          }

          if (mounted) {
            setState(() {
              _shipments = loaded;
              _isLoading = false;
            });
          }

          final enriched = await GoogleNavigationService().enrichShipmentList(loaded);
          if (mounted) {
            setState(() {
              _shipments = enriched;
            });
            return;
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _matchesNonStatusFilters(ShipmentItem item) {
    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          item.id.toLowerCase().contains(query) ||
          item.originTitle.toLowerCase().contains(query) ||
          item.originAddress.toLowerCase().contains(query) ||
          item.destTitle.toLowerCase().contains(query) ||
          item.destAddress.toLowerCase().contains(query) ||
          item.cargoType.toLowerCase().contains(query) ||
          item.equipmentType.toLowerCase().contains(query);
      if (!matchesSearch) return false;
    }

    // 2. Cargo Type Filter
    if (_selectedCargoType != 'All') {
      final target = _selectedCargoType.toLowerCase();
      final matchesCargo =
          item.cargoType.toLowerCase().contains(target) ||
          item.equipmentType.toLowerCase().contains(target) ||
          item.serviceType.toLowerCase().contains(target);
      if (!matchesCargo) return false;
    }

    // 3. Date Filter
    if (_selectedDatePreset != 'All') {
      final itemDate = _getEffectiveDate(item);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (_selectedDatePreset == 'Today') {
        if (itemDate != null) {
          if (!_isSameDay(itemDate, today)) return false;
        } else {
          final isTodayStr =
              item.date.toLowerCase().contains('today') ||
              item.pickupDate.toLowerCase().contains('today');
          if (!isTodayStr) return false;
        }
      } else if (_selectedDatePreset == 'Tomorrow') {
        final tomorrow = today.add(const Duration(days: 1));
        if (itemDate != null) {
          if (!_isSameDay(itemDate, tomorrow)) return false;
        } else {
          final isTomorrowStr =
              item.date.toLowerCase().contains('tomorrow') ||
              item.pickupDate.toLowerCase().contains('tomorrow');
          if (!isTomorrowStr) return false;
        }
      } else if (_selectedDatePreset == 'This Week') {
        if (itemDate == null) return false;
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (itemDate.isBefore(startOfWeek) || itemDate.isAfter(endOfWeek)) {
          return false;
        }
      } else if (_selectedDatePreset == 'Custom') {
        if (_customDateRange == null || itemDate == null) return false;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
        );
        if (itemDate.isBefore(start) || itemDate.isAfter(end)) {
          return false;
        }
      }
    }

    // 4. Time Window Filter
    if (_selectedTimeWindow != 'All') {
      final hours = _parseShipmentHours(item);
      if (hours.isEmpty) {
        return false;
      }
      if (_selectedTimeWindow.contains('Morning')) {
        // Morning: 6 AM to 12 PM (6 <= h < 12)
        final matches = hours.any((h) => h >= 6 && h < 12);
        if (!matches) return false;
      } else if (_selectedTimeWindow.contains('Afternoon')) {
        // Afternoon: 12 PM to 5 PM (12 <= h < 17)
        final matches = hours.any((h) => h >= 12 && h < 17);
        if (!matches) return false;
      } else if (_selectedTimeWindow.contains('Evening')) {
        // Evening: 5 PM to 6 AM (h >= 17 || h < 6)
        final matches = hours.any((h) => h >= 17 || h < 6);
        if (!matches) return false;
      }
    }

    return true;
  }

  List<ShipmentItem> get _filteredShipments {
    final list = _shipments.where((item) {
      // 1. Status Filter
      final matchesFilter =
          _selectedFilter == ShipmentFilter.all ||
          item.status == _selectedFilter;
      if (!matchesFilter) return false;

      // 2. Non-status filters
      return _matchesNonStatusFilters(item);
    }).toList();

    // Sorting
    if (_selectedSortBy == 'shortestDist') {
      list.sort((a, b) {
        if (a.distanceKm <= 0 && b.distanceKm > 0) return 1;
        if (b.distanceKm <= 0 && a.distanceKm > 0) return -1;
        return a.distanceKm.compareTo(b.distanceKm);
      });
    } else if (_selectedSortBy == 'longestDist') {
      list.sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
    } else if (_selectedSortBy == 'earliest') {
      list.sort((a, b) {
        final dateA = _getEffectiveDate(a) ?? DateTime(2099);
        final dateB = _getEffectiveDate(b) ?? DateTime(2099);
        final dateComp = dateA.compareTo(dateB);
        if (dateComp != 0) return dateComp;
        final hoursA = _parseShipmentHours(a);
        final hoursB = _parseShipmentHours(b);
        final hourA = hoursA.isNotEmpty ? hoursA.first : 99;
        final hourB = hoursB.isNotEmpty ? hoursB.first : 99;
        return hourA.compareTo(hourB);
      });
    }

    return list;
  }

  Color _getStatusColor(ShipmentFilter status) {
    switch (status) {
      case ShipmentFilter.inProgress:
        return const Color(0xFF0284C7);
      case ShipmentFilter.scheduled:
        return const Color(0xFFD97706);
      case ShipmentFilter.completed:
        return const Color(0xFF059669);
      case ShipmentFilter.cancelled:
        return const Color(0xFFDC2626);
      default:
        return primaryColor;
    }
  }

  Color _getStatusBg(ShipmentFilter status) {
    switch (status) {
      case ShipmentFilter.inProgress:
        return const Color(0xFFF0F9FF);
      case ShipmentFilter.scheduled:
        return const Color(0xFFFFFBEB);
      case ShipmentFilter.completed:
        return const Color(0xFFECFDF5);
      case ShipmentFilter.cancelled:
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _getFilterLabel(ShipmentFilter filter) {
    switch (filter) {
      case ShipmentFilter.all:
        return 'All';
      case ShipmentFilter.inProgress:
        return 'Active';
      case ShipmentFilter.scheduled:
        return 'Scheduled';
      case ShipmentFilter.completed:
        return 'Completed';
      case ShipmentFilter.cancelled:
        return 'Cancelled';
    }
  }

  int _getDatePresetCount(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (preset == 'Today') {
      return _shipments.where((s) {
        final d = _getEffectiveDate(s);
        if (d != null) {
          return _isSameDay(d, today);
        }
        return s.date.toLowerCase().contains('today') ||
            s.pickupDate.toLowerCase().contains('today');
      }).length;
    } else if (preset == 'Tomorrow') {
      final tom = today.add(const Duration(days: 1));
      return _shipments.where((s) {
        final d = _getEffectiveDate(s);
        if (d != null) {
          return _isSameDay(d, tom);
        }
        return s.date.toLowerCase().contains('tomorrow') ||
            s.pickupDate.toLowerCase().contains('tomorrow');
      }).length;
    } else if (preset == 'This Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return _shipments.where((s) {
        final d = _getEffectiveDate(s);
        return d != null && !d.isBefore(startOfWeek) && !d.isAfter(endOfWeek);
      }).length;
    }
    return _shipments.length;
  }

  int _getCount(ShipmentFilter filter) {
    if (filter == ShipmentFilter.all) {
      return _shipments.where(_matchesNonStatusFilters).length;
    }
    return _shipments
        .where((item) => item.status == filter && _matchesNonStatusFilters(item))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  if (widget.showBackButton && canPop)
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 14.0),
                        child: Icon(
                          Icons.arrow_back,
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'My Shipments',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  // Live Load Board (Coming Soon)
                  GestureDetector(
                    onTap: () => ComingSoonModal.show(
                      context,
                      featureName: 'Live Load Board & Spot Freight',
                      description: 'Browse available spot freight, claim priority carrier load routes, and dispatch directly from certified shippers.',
                      icon: Icons.local_shipping_rounded,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFFFFCCBC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Load Board',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter options button
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _activeAdvancedFilterCount > 0
                            ? AppColors.primaryLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: _activeAdvancedFilterCount > 0
                              ? AppColors.primary
                              : AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: _activeAdvancedFilterCount > 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _activeAdvancedFilterCount > 0
                                ? 'Filter ($_activeAdvancedFilterCount)'
                                : 'Filter',
                            style: GoogleFonts.inter(
                              color: _activeAdvancedFilterCount > 0
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar with rounded stadium shape and enterprise styling
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                  ),
                  cursorColor: AppColors.primary,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: 'Search shipments by ID, location...',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14.0, right: 8.0),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 44,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Horizontal Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip(ShipmentFilter.all, 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip(ShipmentFilter.inProgress, 'Active'),
                    const SizedBox(width: 8),
                    _buildFilterChip(ShipmentFilter.scheduled, 'Scheduled'),
                    const SizedBox(width: 8),
                    _buildFilterChip(ShipmentFilter.completed, 'Completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip(ShipmentFilter.cancelled, 'Cancelled'),
                  ],
                ),
              ),
            ),

            // Active Advanced Filter Badges (if any active)
            if (_activeAdvancedFilterCount > 0) _buildActiveFiltersBar(),

            // Shipment List
            Expanded(
              child: _isLoading
                  ? const LoadingState(
                      itemCount: 4,
                      padding: EdgeInsets.all(16),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchShipments,
                      child: _filteredShipments.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _filteredShipments.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _filteredShipments[index];
                                return _buildShipmentListItem(item);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ShipmentFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    final count = _getCount(filter);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentListItem(ShipmentItem item) {
    final statusColor = item.isEmergency ? const Color(0xFFCF222E) : _getStatusColor(item.status);
    final statusBg = item.isEmergency ? const Color(0xFFFEF2F2) : _getStatusBg(item.status);

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShipmentDetailsScreen(shipment: item),
          ),
        );
        if (mounted) {
          _fetchShipments();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: [Order Number] on left, [Cargo Badge + Status Badge] on right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${item.id}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7.5,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(
                        item.cargoType,
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        item.isEmergency ? 'Emergency Hold' : item.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Date & Time Row (Full Width - No Truncation, No Ellipsis)
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    (item.date.isNotEmpty &&
                            item.time.isNotEmpty &&
                            item.date != 'Today')
                        ? '${item.date} • ${item.time}'
                        : (item.time.isNotEmpty
                              ? item.time
                              : (item.date.isNotEmpty
                                    ? item.date
                                    : 'Scheduled')),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Origin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF16A34A), // Distinct Green for Pickup
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.originTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.originAddress,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
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
              padding: const EdgeInsets.only(left: 8.25, top: 2, bottom: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: 1.5,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),

            // Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFE53935),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.destTitle,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.destAddress,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 8),

            // Bottom Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        size: 13.5,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${item.formattedDistance} total',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (item.status == ShipmentFilter.inProgress) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InAppNavigationScreen(shipment: item),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.navigation_rounded,
                                  size: 10,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'LIVE GPS',
                                  style: TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${item.palletQuantity} • ${item.payloadWeight}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No Shipments Found',
      subtitle: 'No shipment records match your active search or filter.',
      actionLabel:
          (_searchQuery.isNotEmpty ||
              _selectedFilter != ShipmentFilter.all ||
              _activeAdvancedFilterCount > 0)
          ? 'Reset Filters'
          : null,
      onAction: () {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _selectedFilter = ShipmentFilter.all;
          _selectedDatePreset = 'All';
          _selectedTimeWindow = 'All';
          _selectedCargoType = 'All';
          _selectedSortBy = 'default';
        });
      },
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (_selectedDatePreset != 'All')
              _buildActivePill(
                label:
                    _selectedDatePreset == 'Custom' && _customDateRange != null
                    ? '${_formatDateShort(_customDateRange!.start)} - ${_formatDateShort(_customDateRange!.end)}'
                    : 'Date: $_selectedDatePreset',
                icon: Icons.calendar_today_rounded,
                onRemove: () {
                  setState(() {
                    _selectedDatePreset = 'All';
                    _customDateRange = null;
                  });
                },
              ),
            if (_selectedTimeWindow != 'All') ...[
              const SizedBox(width: 6),
              _buildActivePill(
                label: _selectedTimeWindow.split(' (').first,
                icon: Icons.access_time_rounded,
                onRemove: () {
                  setState(() {
                    _selectedTimeWindow = 'All';
                  });
                },
              ),
            ],
            if (_selectedCargoType != 'All') ...[
              const SizedBox(width: 6),
              _buildActivePill(
                label: 'Cargo: $_selectedCargoType',
                icon: Icons.inventory_2_outlined,
                onRemove: () {
                  setState(() {
                    _selectedCargoType = 'All';
                  });
                },
              ),
            ],
            if (_selectedSortBy != 'default') ...[
              const SizedBox(width: 6),
              _buildActivePill(
                label: _selectedSortBy == 'shortestDist'
                    ? 'Shortest Dist'
                    : _selectedSortBy == 'longestDist'
                    ? 'Longest Dist'
                    : 'Earliest Pickup',
                icon: Icons.sort_rounded,
                onRemove: () {
                  setState(() {
                    _selectedSortBy = 'default';
                  });
                },
              ),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDatePreset = 'All';
                  _customDateRange = null;
                  _selectedTimeWindow = 'All';
                  _selectedCargoType = 'All';
                  _selectedSortBy = 'default';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePill({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EB),
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: const Color(0xFFFFCCBC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFF5722)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF5722),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFFFF5722),
            ),
          ),
        ],
      ),
    );
  }

  Future<DateTimeRange?> _showCustomDateRangeBottomSheet(
    BuildContext ctx,
    DateTimeRange? currentRange,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime startDate = currentRange?.start ?? today;
    DateTime endDate = currentRange?.end ?? today.add(const Duration(days: 7));
    int activeTab = 0; // 0 = start date, 1 = end date
    final firstAllowedDate = DateTime(now.year - 2);
    final lastAllowedDate = DateTime(now.year + 2);

    return showModalBottomSheet<DateTimeRange?>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            void applyPreset(int days) {
              setModalState(() {
                startDate = today;
                endDate = today.add(Duration(days: days));
              });
            }

            DateTime initialCalDate = (activeTab == 0 ? startDate : endDate);
            if (initialCalDate.isBefore(firstAllowedDate)) {
              initialCalDate = firstAllowedDate;
            }
            if (initialCalDate.isAfter(lastAllowedDate)) {
              initialCalDate = lastAllowedDate;
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.date_range_rounded,
                              color: Color(0xFFFF5722),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Date Range',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Choose start and end pickup dates',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 18,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),

                    // Start and End Cards Selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: activeTab == 0
                                      ? const Color(0xFFFFF1EB)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: activeTab == 0
                                        ? const Color(0xFFFF5722)
                                        : const Color(0xFFE2E8F0),
                                    width: activeTab == 0 ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FROM DATE',
                                      style: TextStyle(
                                        color: activeTab == 0
                                            ? const Color(0xFFFF5722)
                                            : const Color(0xFF64748B),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatDateShort(startDate),
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: activeTab == 1
                                      ? const Color(0xFFFFF1EB)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: activeTab == 1
                                        ? const Color(0xFFFF5722)
                                        : const Color(0xFFE2E8F0),
                                    width: activeTab == 1 ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TO DATE',
                                      style: TextStyle(
                                        color: activeTab == 1
                                            ? const Color(0xFFFF5722)
                                            : const Color(0xFF64748B),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatDateShort(endDate),
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Quick range helpers
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildQuickRangeChip(
                            'Next 3 Days',
                            () => applyPreset(3),
                          ),
                          const SizedBox(width: 6),
                          _buildQuickRangeChip(
                            'Next 7 Days',
                            () => applyPreset(7),
                          ),
                          const SizedBox(width: 6),
                          _buildQuickRangeChip(
                            'Next 14 Days',
                            () => applyPreset(14),
                          ),
                          const SizedBox(width: 6),
                          _buildQuickRangeChip(
                            'Next 30 Days',
                            () => applyPreset(30),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Interactive Calendar Picker
                    Expanded(
                      child: Theme(
                        data: Theme.of(bottomSheetContext).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF5722),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF0F172A),
                          ),
                        ),
                        child: CalendarDatePicker(
                          key: ValueKey(
                            'cal_${activeTab}_${initialCalDate.millisecondsSinceEpoch}',
                          ),
                          initialDate: initialCalDate,
                          firstDate: firstAllowedDate,
                          lastDate: lastAllowedDate,
                          onDateChanged: (DateTime picked) {
                            setModalState(() {
                              if (activeTab == 0) {
                                startDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate.add(
                                    const Duration(days: 1),
                                  );
                                }
                                activeTab = 1;
                              } else {
                                final candidate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                                if (candidate.isBefore(startDate)) {
                                  startDate = candidate;
                                } else {
                                  endDate = candidate;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  bottomSheetContext,
                                  DateTimeRange(start: startDate, end: endDate),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Set Date Range',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickRangeChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    var tempFilter = _selectedFilter;
    var tempDatePreset = _selectedDatePreset;
    DateTimeRange? tempCustomDateRange = _customDateRange;
    var tempTimeWindow = _selectedTimeWindow;
    var tempCargoType = _selectedCargoType;
    var tempSortBy = _selectedSortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildSectionTitle(String title, IconData icon) {
              return Padding(
                padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
                child: Row(
                  children: [
                    Icon(icon, size: 15, color: const Color(0xFFFF5722)),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildChip({
              required String label,
              required bool isSelected,
              required VoidCallback onTap,
              IconData? icon,
            }) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF5722)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF5722)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 13,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    // Drag handle
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Top header: Title & Reset Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advanced Filters',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Refine shipments by date, time, type & order',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempFilter = ShipmentFilter.all;
                                tempDatePreset = 'All';
                                tempCustomDateRange = null;
                                tempTimeWindow = 'All';
                                tempCargoType = 'All';
                                tempSortBy = 'default';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1EB),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: const Text(
                                'Reset All',
                                style: TextStyle(
                                  color: Color(0xFFFF5722),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 20,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),

                    // Scrollable Filter Sections
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Delivery Status
                            buildSectionTitle(
                              'Delivery Status',
                              Icons.local_shipping_outlined,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ShipmentFilter.values.map((f) {
                                final isSel = tempFilter == f;
                                final count = f == ShipmentFilter.all
                                    ? _shipments.length
                                    : _shipments.where((s) => s.status == f).length;
                                final name = _getFilterLabel(f);
                                return buildChip(
                                  label: '$name ($count)',
                                  isSelected: isSel,
                                  onTap: () {
                                    setModalState(() => tempFilter = f);
                                  },
                                );
                              }).toList(),
                            ),

                            // 2. Date Window
                            buildSectionTitle(
                              'Pickup Date Window',
                              Icons.calendar_month_outlined,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                buildChip(
                                  label: 'All Dates (${_shipments.length})',
                                  isSelected: tempDatePreset == 'All',
                                  onTap: () {
                                    setModalState(() {
                                      tempDatePreset = 'All';
                                      tempCustomDateRange = null;
                                    });
                                  },
                                ),
                                buildChip(
                                  label: 'Today (${_getDatePresetCount('Today')})',
                                  isSelected: tempDatePreset == 'Today',
                                  onTap: () {
                                    setModalState(
                                      () => tempDatePreset = 'Today',
                                    );
                                  },
                                ),
                                buildChip(
                                  label: 'Tomorrow (${_getDatePresetCount('Tomorrow')})',
                                  isSelected: tempDatePreset == 'Tomorrow',
                                  onTap: () {
                                    setModalState(
                                      () => tempDatePreset = 'Tomorrow',
                                    );
                                  },
                                ),
                                buildChip(
                                  label: 'This Week (${_getDatePresetCount('This Week')})',
                                  isSelected: tempDatePreset == 'This Week',
                                  onTap: () {
                                    setModalState(
                                      () => tempDatePreset = 'This Week',
                                    );
                                  },
                                ),
                                buildChip(
                                  label:
                                      tempDatePreset == 'Custom' &&
                                          tempCustomDateRange != null
                                      ? '${_formatDateShort(tempCustomDateRange!.start)} - ${_formatDateShort(tempCustomDateRange!.end)}'
                                      : 'Custom Date Range',
                                  icon: Icons.date_range_rounded,
                                  isSelected: tempDatePreset == 'Custom',
                                  onTap: () async {
                                    final picked =
                                        await _showCustomDateRangeBottomSheet(
                                          context,
                                          tempCustomDateRange,
                                        );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempDatePreset = 'Custom';
                                        tempCustomDateRange = picked;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),

                            // 3. Time Window
                            buildSectionTitle(
                              'Time Window',
                              Icons.access_time_rounded,
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                buildChip(
                                  label: 'Any Time',
                                  isSelected: tempTimeWindow == 'All',
                                  onTap: () {
                                    setModalState(() => tempTimeWindow = 'All');
                                  },
                                ),
                                buildChip(
                                  label: 'Morning (6 AM - 12 PM)',
                                  isSelected: tempTimeWindow.contains(
                                    'Morning',
                                  ),
                                  onTap: () {
                                    setModalState(
                                      () => tempTimeWindow =
                                          'Morning (6 AM - 12 PM)',
                                    );
                                  },
                                ),
                                buildChip(
                                  label: 'Afternoon (12 PM - 5 PM)',
                                  isSelected: tempTimeWindow.contains(
                                    'Afternoon',
                                  ),
                                  onTap: () {
                                    setModalState(
                                      () => tempTimeWindow =
                                          'Afternoon (12 PM - 5 PM)',
                                    );
                                  },
                                ),
                                buildChip(
                                  label: 'Evening & Night (5 PM - 6 AM)',
                                  isSelected: tempTimeWindow.contains(
                                    'Evening',
                                  ),
                                  onTap: () {
                                    setModalState(
                                      () => tempTimeWindow =
                                          'Evening (5 PM - 6 AM)',
                                    );
                                  },
                                ),
                              ],
                            ),

                            // 4. Cargo Type
                            if (_availableCargoTypes.length > 1) ...[
                              buildSectionTitle(
                                'Cargo Type',
                                Icons.inventory_2_outlined,
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableCargoTypes.map((type) {
                                  final isSel = tempCargoType == type;
                                  final count = type == 'All'
                                      ? _shipments.length
                                      : _shipments
                                          .where(
                                            (s) {
                                              final t = type.toLowerCase();
                                              return s.cargoType.toLowerCase().contains(t) ||
                                                  s.equipmentType.toLowerCase().contains(t) ||
                                                  s.serviceType.toLowerCase().contains(t);
                                            },
                                          )
                                          .length;
                                  return buildChip(
                                    label: type == 'All'
                                        ? 'All Types ($count)'
                                        : '$type ($count)',
                                    isSelected: isSel,
                                    onTap: () {
                                      setModalState(() => tempCargoType = type);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],

                            // 5. Sorting
                            buildSectionTitle('Sort By', Icons.sort_rounded),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                buildChip(
                                  label: 'Default',
                                  isSelected: tempSortBy == 'default',
                                  onTap: () {
                                    setModalState(() => tempSortBy = 'default');
                                  },
                                ),
                                buildChip(
                                  label: 'Earliest Pickup',
                                  icon: Icons.schedule_rounded,
                                  isSelected: tempSortBy == 'earliest',
                                  onTap: () {
                                    setModalState(
                                      () => tempSortBy = 'earliest',
                                    );
                                  },
                                ),
                                buildChip(
                                  label: 'Shortest Distance',
                                  icon: Icons.straighten_rounded,
                                  isSelected: tempSortBy == 'shortestDist',
                                  onTap: () {
                                    setModalState(
                                      () => tempSortBy = 'shortestDist',
                                    );
                                  },
                                ),
                                buildChip(
                                  label: 'Longest Distance',
                                  icon: Icons.route_rounded,
                                  isSelected: tempSortBy == 'longestDist',
                                  onTap: () {
                                    setModalState(
                                      () => tempSortBy = 'longestDist',
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Apply Button Sticky Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = tempFilter;
                              _selectedDatePreset = tempDatePreset;
                              _customDateRange = tempCustomDateRange;
                              _selectedTimeWindow = tempTimeWindow;
                              _selectedCargoType = tempCargoType;
                              _selectedSortBy = tempSortBy;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
