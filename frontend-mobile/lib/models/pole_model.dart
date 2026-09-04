import '../core/constants/app_constants.dart';

class PoleModel {
  final String id; // e.g. "P-001"
  final String location;
  final double latitude;
  final double longitude;
  final String zone;
  final double leakageCurrent; // mA
  final double voltage; // V
  final double temperature; // °C
  final double humidity; // %
  final bool rain;
  final int healthScore; // 0 - 100
  final int riskScore; // 0 - 100
  final RiskTier riskTier;
  final bool humanDetected;
  final bool animalDetected;
  final bool standingWaterDetected;
  final String lastSeen;
  final bool isOnline;

  const PoleModel({
    required this.id,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.zone,
    this.leakageCurrent = 2.1,
    this.voltage = 230.0,
    this.temperature = 28.5,
    this.humidity = 60.0,
    this.rain = false,
    this.healthScore = 95,
    this.riskScore = 5,
    this.riskTier = RiskTier.safe,
    this.humanDetected = false,
    this.animalDetected = false,
    this.standingWaterDetected = false,
    required this.lastSeen,
    this.isOnline = true,
  });
}
