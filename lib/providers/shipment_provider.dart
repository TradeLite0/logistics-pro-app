import 'package:flutter/foundation.dart';
import '../models/shipment_model.dart';
import '../services/shipment_service.dart';

class ShipmentProvider extends ChangeNotifier {
  final ShipmentService _shipmentService = ShipmentService();

  List<ShipmentModel> _shipments = [];
  ShipmentModel? _selectedShipment;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  List<ShipmentModel> get shipments => _shipments;
  ShipmentModel? get selectedShipment => _selectedShipment;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;

  Future<void> loadMyShipments({
    String? status,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _shipments = [];
      _hasMoreData = true;
    }

    if (_isLoading || (_isLoadingMore && !refresh)) return;

    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final newShipments = await _shipmentService.getMyShipments(
        status: status,
        search: search,
        page: _currentPage,
      );

      if (newShipments.length < 20) {
        _hasMoreData = false;
      }

      _shipments.addAll(newShipments);
      _currentPage++;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadDriverShipments({
    String? status,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _shipments = [];
      _hasMoreData = true;
    }

    if (_isLoading || (_isLoadingMore && !refresh)) return;

    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final newShipments = await _shipmentService.getDriverShipments(
        status: status,
        search: search,
        page: _currentPage,
      );

      if (newShipments.length < 20) {
        _hasMoreData = false;
      }

      _shipments.addAll(newShipments);
      _currentPage++;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadShipmentDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedShipment = await _shipmentService.getShipmentDetails(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ShipmentModel> createShipment(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final shipment = await _shipmentService.createShipment(data);
      _shipments.insert(0, shipment);
      _error = null;
      return shipment;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateShipmentStatus(String id, String status) async {
    try {
      await _shipmentService.updateShipmentStatus(id, status);
      
      // Update local list
      final index = _shipments.indexWhere((s) => s.id == id);
      if (index != -1) {
        _shipments[index] = ShipmentModel(
          id: _shipments[index].id,
          trackingNumber: _shipments[index].trackingNumber,
          status: status,
          weight: _shipments[index].weight,
          pickupAddress: _shipments[index].pickupAddress,
          deliveryAddress: _shipments[index].deliveryAddress,
          createdAt: _shipments[index].createdAt,
          description: _shipments[index].description,
          price: _shipments[index].price,
          clientId: _shipments[index].clientId,
          driverId: _shipments[index].driverId,
          pickupDate: _shipments[index].pickupDate,
          deliveryDate: _shipments[index].deliveryDate,
          updatedAt: DateTime.now(),
          client: _shipments[index].client,
          driver: _shipments[index].driver,
        );
      }

      // Update selected shipment if matches
      if (_selectedShipment?.id == id) {
        _selectedShipment = ShipmentModel(
          id: _selectedShipment!.id,
          trackingNumber: _selectedShipment!.trackingNumber,
          status: status,
          weight: _selectedShipment!.weight,
          pickupAddress: _selectedShipment!.pickupAddress,
          deliveryAddress: _selectedShipment!.deliveryAddress,
          createdAt: _selectedShipment!.createdAt,
          description: _selectedShipment!.description,
          price: _selectedShipment!.price,
          clientId: _selectedShipment!.clientId,
          driverId: _selectedShipment!.driverId,
          pickupDate: _selectedShipment!.pickupDate,
          deliveryDate: _selectedShipment!.deliveryDate,
          updatedAt: DateTime.now(),
          client: _selectedShipment!.client,
          driver: _selectedShipment!.driver,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<ShipmentModel?> trackShipment(String trackingNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final shipment = await _shipmentService.trackShipment(trackingNumber);
      _error = null;
      return shipment;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedShipment() {
    _selectedShipment = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
