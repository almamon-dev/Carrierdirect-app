enum TripStatus { pending, accepted, inProgress, completed, cancelled }

class TripModel {
  final String id;
  final String pickupLocation;
  final String dropoffLocation;
  final double distanceKm;
  final String cargoType;
  final TripStatus status;
  final DateTime createdAt;

  const TripModel({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distanceKm,
    required this.cargoType,
    required this.status,
    required this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropoffLocation: json['dropoff_location'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      cargoType: json['cargo_type'] as String? ?? 'Dry Van 53ft',
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
