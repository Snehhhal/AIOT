import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
}

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  LocationPermissionState _permissionState = LocationPermissionState.unknown;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LocationPermissionState get permissionState => _permissionState;

  bool get hasPosition => _currentPosition != null;
  double? get effectiveLatitude => _currentPosition?.latitude;
  double? get effectiveLongitude => _currentPosition?.longitude;

  String get locationSourceLabel {
    if (_currentPosition != null) {
      return 'Live GPS (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})';
    }
    switch (_permissionState) {
      case LocationPermissionState.servicesDisabled:
        return 'GPS Hardware Disabled';
      case LocationPermissionState.denied:
        return 'Permission Denied';
      case LocationPermissionState.permanentlyDenied:
        return 'Permission Blocked (Settings)';
      default:
        return 'GPS Unavailable';
    }
  }

  /// Checks device location status and requests native OS permission if needed
  Future<void> fetchDeviceLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if device location service (hardware GPS toggle) is on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _permissionState = LocationPermissionState.servicesDisabled;
        _errorMessage = 'Device Location Service (GPS) is turned off. Please enable GPS.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Check native permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _permissionState = LocationPermissionState.denied;
          _errorMessage = 'Location permission was denied. Nearby pole check requires GPS access.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _permissionState = LocationPermissionState.permanentlyDenied;
        _errorMessage = 'Location permission is permanently denied. Please enable in App Settings.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 3. Permission granted: query high-accuracy hardware position
      _permissionState = LocationPermissionState.granted;
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to acquire GPS position: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deep link into Android/iOS App Settings for permanently denied permission
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Deep link into device Location Settings for disabled GPS hardware
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

