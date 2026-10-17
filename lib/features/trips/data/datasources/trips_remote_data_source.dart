import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/trip_model.dart';

abstract class ITripsRemoteDataSource {
  Future<List<TripModel>> getTrips();
}

class TripsRemoteDataSource implements ITripsRemoteDataSource {
  final ApiClient _apiClient;

  TripsRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<TripModel>> getTrips() async {
    try {
      final response = await _apiClient.get(
        endpoint: ApiConstants.trips,
        fromJson: (data) {
          final list = data as List;
          return list.map((e) => TripModel.fromJson(e as Map<String, dynamic>)).toList();
        },
      );
      return response.data ?? [];
    } catch (_) {
      // Mock trips fallback
      return [
        TripModel(
          id: 'CD-8921',
          pickupLocation: 'Logistics Hub Alpha, Dock 4',
          dropoffLocation: 'Metro Distribution Center, Zone B',
          distanceKm: 24.5,
          cargoType: 'Dry Van 53ft',
          status: TripStatus.inProgress,
          createdAt: DateTime.now(),
        ),
        TripModel(
          id: 'CD-8919',
          pickupLocation: 'South Terminal Cargo 2',
          dropoffLocation: 'Apex Retail Warehouse',
          distanceKm: 18.2,
          cargoType: 'Reefer Trailer',
          status: TripStatus.completed,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
    }
  }
}
