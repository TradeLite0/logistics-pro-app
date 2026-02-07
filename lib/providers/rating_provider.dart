import 'package:flutter/foundation.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';

class RatingProvider extends ChangeNotifier {
  final RatingService _ratingService = RatingService();

  List<RatingModel> _ratings = [];
  DriverRatingSummary? _ratingSummary;
  bool _isLoading = false;
  String? _error;
  bool _hasRated = false;
  RatingModel? _myRating;

  List<RatingModel> get ratings => _ratings;
  DriverRatingSummary? get ratingSummary => _ratingSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRated => _hasRated;
  RatingModel? get myRating => _myRating;

  Future<void> loadDriverRatings(String driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ratings = await _ratingService.getDriverRatings(driverId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDriverRatingSummary(String driverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ratingSummary = await _ratingService.getDriverRatingSummary(driverId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createRating(String shipmentId, String driverId, double rating, {String? comment}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = CreateRatingRequest(
        shipmentId: shipmentId,
        driverId: driverId,
        rating: rating,
        comment: comment,
      );
      final newRating = await _ratingService.createRating(request);
      _ratings.insert(0, newRating);
      _myRating = newRating;
      _hasRated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkCanRate(String shipmentId) async {
    try {
      _hasRated = await _ratingService.canRateDriver(shipmentId);
    } catch (e) {
      _hasRated = false;
    }
    notifyListeners();
  }

  Future<void> loadMyRating(String shipmentId) async {
    try {
      _myRating = await _ratingService.getMyRatingForShipment(shipmentId);
      _hasRated = _myRating != null;
    } catch (e) {
      _myRating = null;
      _hasRated = false;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
