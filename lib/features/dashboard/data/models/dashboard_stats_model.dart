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

  factory DashboardStatsModel.mock() {
    return const DashboardStatsModel(
      activeLoads: 2,
      completedTrips: 8,
      totalDistanceKm: 142.6,
      rating: 4.95,
      activeHours: 6.5,
    );
  }
}
