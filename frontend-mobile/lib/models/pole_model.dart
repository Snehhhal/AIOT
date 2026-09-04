import '../core/constants/app_constants.dart';

class PoleModel {
  final String id; // e.g. "P-001"
  final String? serialNumber;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final String zone;
  final String status; // HEALTHY, WARNING, CRITICAL, OFFLINE
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
  final String? lastSeen;
  final bool isOnline;

  String get locationName => location.isNotEmpty ? location : name;

  const PoleModel({
    required this.id,
    this.serialNumber,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.zone,
    this.status = "HEALTHY",
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
    this.lastSeen,
    this.isOnline = true,
  });

  factory PoleModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? 'HEALTHY').toString().toUpperCase();
    final riskScoreVal = (json['risk_score'] ?? 5) as int;
    
    RiskTier tier = RiskTier.safe;
    if (riskScoreVal >= 85 || statusStr == 'CRITICAL') {
      tier = RiskTier.emergency;
    } else if (riskScoreVal >= 60) {
      tier = RiskTier.critical;
    } else if (riskScoreVal >= 30 || statusStr == 'WARNING') {
      tier = RiskTier.warning;
    }

    final latestReading = json['latest_reading'] as Map<String, dynamic>?;

    return PoleModel(
      id: json['id'] ?? 'P-000',
      serialNumber: json['serial_number'],
      name: json['name'] ?? 'Utility Pole',
      location: json['name'] ?? 'Distribution Node',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
      zone: json['zone'] ?? 'Sector 1',
      status: statusStr,
      healthScore: (json['health_score'] as num?)?.toInt() ?? 95,
      riskScore: riskScoreVal,
      riskTier: tier,
      leakageCurrent: latestReading != null ? (latestReading['leakage_current'] as num).toDouble() : (json['leakage_current'] as num?)?.toDouble() ?? 2.1,
      voltage: latestReading != null ? (latestReading['voltage'] as num).toDouble() : (json['voltage'] as num?)?.toDouble() ?? 230.0,
      temperature: latestReading != null ? (latestReading['temperature'] as num).toDouble() : (json['temperature'] as num?)?.toDouble() ?? 28.0,
      humidity: latestReading != null ? (latestReading['humidity'] as num).toDouble() : (json['humidity'] as num?)?.toDouble() ?? 55.0,
      rain: latestReading != null ? (latestReading['rain'] as bool? ?? false) : (json['rain'] as bool? ?? false),
      humanDetected: json['human_detected'] as bool? ?? false,
      animalDetected: json['animal_detected'] as bool? ?? false,
      standingWaterDetected: json['standing_water_detected'] as bool? ?? false,
      lastSeen: json['last_heartbeat'],
      isOnline: (json['connectivity'] ?? 'ONLINE') == 'ONLINE',
    );
  }

  PoleModel copyWith({
    String? status,
    double? leakageCurrent,
    double? voltage,
    double? temperature,
    double? humidity,
    bool? rain,
    int? healthScore,
    int? riskScore,
    RiskTier? riskTier,
    bool? humanDetected,
    bool? animalDetected,
    bool? standingWaterDetected,
    bool? isOnline,
  }) {
    return PoleModel(
      id: id,
      serialNumber: serialNumber,
      name: name,
      location: location,
      latitude: latitude,
      longitude: longitude,
      zone: zone,
      status: status ?? this.status,
      leakageCurrent: leakageCurrent ?? this.leakageCurrent,
      voltage: voltage ?? this.voltage,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      rain: rain ?? this.rain,
      healthScore: healthScore ?? this.healthScore,
      riskScore: riskScore ?? this.riskScore,
      riskTier: riskTier ?? this.riskTier,
      humanDetected: humanDetected ?? this.humanDetected,
      animalDetected: animalDetected ?? this.animalDetected,
      standingWaterDetected: standingWaterDetected ?? this.standingWaterDetected,
      lastSeen: lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
