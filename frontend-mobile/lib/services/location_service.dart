import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isTestLocationMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Test Location default: Sector 4 Distribution Hub (18.5204, 73.8567)
  static const double testLatitude = 18.5204;
  static const double testLongitude = 73.8567;
  static const String testLocationName = "Sector 4 — MG Road Junction";

  Position? get currentPosition => _currentPosition;
  bool get isTestLocationMode => _isTestLocationMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get effectiveLatitude => _isTestLocationMode || _currentPosition == null
      ? testLatitude
      : _currentPosition!.latitude;

  double get effectiveLongitude => _isTestLocationMode || _currentPosition == null
      ? testLongitude
      : _currentPosition!.longitude;

  String get locationSourceLabel => _isTestLocationMode
      ? "Test Location Mode ($testLocationName)"
      : (_currentPosition != null ? "Live Phone GPS" : "Fallback ($testLocationName)");

  void toggleTestLocationMode() {
    _isTestLocationMode = !_isTestLocationMode;
    notifyListeners();
  }

  /// Obtains current GPS coordinates from the phone hardware
  Future<void> fetchDeviceLocation() async {
    if (_isTestLocationMode) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = "GPS is disabled on device. Using development coordinates.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = "Location permission denied. Using development coordinates.";
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = "Location permission permanently denied. Enable in device settings.";
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      _errorMessage = "GPS acquisition error: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
