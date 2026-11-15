class DashboardStatsModel {
  final int activeLoads;
  final int completedTrips;
  final double totalDistanceKm;
  final double rating;
  final double activeHours;

  const DashboardStatsModel({
    required this.activeLoads,
    required this.completedTrips,
    required this.totalDistanceKm,
    required this.rating,
    required this.activeHours,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      activeLoads:
          int.tryParse(json['active_shipments']?.toString() ?? '') ??
          (int.tryParse(json['total_assigned']?.toString() ?? '') ?? 0),
      completedTrips:
          int.tryParse(json['delivered_count']?.toString() ?? '') ?? 0,
      totalDistanceKm:
          double.tryParse(json['total_distance_km']?.toString() ?? '') ?? 0.0,
      rating: double.tryParse(json['driver_rating']?.toString() ?? '') ?? 5.0,
      activeHours:
          double.tryParse(json['active_hours']?.toString() ?? '') ?? 8.0,
    );
  }

  factory DashboardStatsModel.mock() {
    return const DashboardStatsModel(
      activeLoads: 0,
      completedTrips: 0,
      totalDistanceKm: 0.0,
      rating: 5.0,
      activeHours: 0.0,
    );
  }
}
