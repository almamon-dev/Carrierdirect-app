import 'package:flutter/material.dart';

import '../../data/models/trip_model.dart';
import '../../data/repositories/trips_repository.dart';

class TripsController extends ChangeNotifier {
  final ITripsRepository _repository;

  TripsController({ITripsRepository? repository})
    : _repository = repository ?? TripsRepository();

  List<TripModel> _trips = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trips = await _repository.getTrips();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
