import 'package:flutter/material.dart';

import '../../data/models/dashboard_stats_model.dart';

class DashboardController extends ChangeNotifier {
  bool _isOnline = false;
  DashboardStatsModel _stats = DashboardStatsModel.mock();
  bool _isLoading = false;

  bool get isOnline => _isOnline;
  DashboardStatsModel get stats => _stats;
  bool get isLoading => _isLoading;

  void toggleOnlineStatus() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _stats = DashboardStatsModel.mock();

    _isLoading = false;
    notifyListeners();
  }
}
