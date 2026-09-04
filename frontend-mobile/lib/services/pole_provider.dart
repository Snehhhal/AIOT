import 'package:flutter/material.dart';
import '../models/pole_model.dart';
import '../core/constants/app_constants.dart';
import 'api_client.dart';

class PoleProvider extends ChangeNotifier {
  List<PoleModel> _poles = [];
  PoleModel? _selectedPole;
  bool _isLoading = false;
  String? _errorMessage;

  List<PoleModel> get poles => _poles;
  PoleModel? get selectedPole => _selectedPole ?? (_poles.isNotEmpty ? _poles.first : null);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fleet Statistics
  int get totalCount => _poles.length;
  int get emergencyCount => _poles.where((p) => p.riskTier == RiskTier.emergency).length;
  int get warningCount => _poles.where((p) => p.riskTier == RiskTier.warning).length;
  int get healthyCount => _poles.where((p) => p.riskTier == RiskTier.safe).length;
  double get averageHealth => _poles.isEmpty
      ? 95.0
      : _poles.map((p) => p.healthScore).reduce((a, b) => a + b) / _poles.length;

  PoleProvider() {
    loadPoles();
  }

  Future<void> loadPoles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _poles = await ApiClient.getPoles();
      _errorMessage = null;
      if (_poles.isNotEmpty && _selectedPole == null) {
        _selectedPole = _poles.first;
      }
    } catch (e) {
      _errorMessage = 'Failed to load poles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPole(String poleId) {
    _selectedPole = _poles.firstWhere((p) => p.id == poleId, orElse: () => _poles.first);
    notifyListeners();
  }

  /// Trigger simulation scenario on a target pole (Section 42 & 43 Demo Mode)
  Future<void> triggerScenario(String poleId, String scenario) async {
    double leakage = 1.5;
    double voltage = 230.0;
    bool rain = false;
    bool human = false;
    bool water = false;
    int health = 95;
    int risk = 5;
    RiskTier tier = RiskTier.safe;
    String status = "HEALTHY";

    if (scenario == "LEAKAGE") {
      leakage = 36.5;
      voltage = 55.0;
      risk = 65;
      health = 72;
      tier = RiskTier.critical;
      status = "WARNING";
    } else if (scenario == "LEAKAGE_RAIN") {
      leakage = 42.0;
      voltage = 68.0;
      rain = true;
      risk = 82;
      health = 64;
      tier = RiskTier.emergency;
      status = "CRITICAL";
    } else if (scenario == "HUMAN_PROXIMITY") {
      leakage = 38.0;
      voltage = 62.0;
      rain = true;
      human = true;
      risk = 88;
      health = 60;
      tier = RiskTier.emergency;
      status = "CRITICAL";
    } else if (scenario == "FULL_EMERGENCY") {
      leakage = 48.5;
      voltage = 74.2;
      rain = true;
      human = true;
      water = true;
      risk = 94;
      health = 58;
      tier = RiskTier.emergency;
      status = "CRITICAL";
    }

    // 1. Send live packet to FastAPI if backend running
    final payload = {
      "pole_id": poleId,
      "leakage_current_ma": leakage,
      "touch_voltage_v": voltage,
      "tilt_angle_deg": 1.2,
      "vibration_g": 0.04,
      "temperature_c": 28.0,
      "humidity_pct": rain ? 95.0 : 50.0,
      "rain_detected": rain,
      "is_simulated": true,
    };
    ApiClient.sendTelemetry(payload);

    // 2. Update local state immediately for instant responsive UI in Demo
    final index = _poles.indexWhere((p) => p.id == poleId);
    if (index != -1) {
      _poles[index] = _poles[index].copyWith(
        status: status,
        leakageCurrent: leakage,
        voltage: voltage,
        rain: rain,
        humanDetected: human,
        standingWaterDetected: water,
        healthScore: health,
        riskScore: risk,
        riskTier: tier,
      );
      if (_selectedPole?.id == poleId) {
        _selectedPole = _poles[index];
      }
      notifyListeners();
    }
  }
}
