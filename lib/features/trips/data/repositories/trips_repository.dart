import '../datasources/trips_remote_data_source.dart';
import '../models/trip_model.dart';

abstract class ITripsRepository {
  Future<List<TripModel>> getTrips();
}

class TripsRepository implements ITripsRepository {
  final ITripsRemoteDataSource _remoteDataSource;

  TripsRepository({ITripsRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? TripsRemoteDataSource();

  @override
  Future<List<TripModel>> getTrips() async {
    return await _remoteDataSource.getTrips();
  }
}
