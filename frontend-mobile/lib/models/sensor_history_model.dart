class SensorHistoryPoint {
  final DateTime timestamp;
  final double leakageCurrent;
  final double voltage;
  final double temperature;
  final double humidity;
  final double tiltAngle;
  final bool rain;

  const SensorHistoryPoint({
    required this.timestamp,
    required this.leakageCurrent,
    required this.voltage,
    required this.temperature,
    required this.humidity,
    this.tiltAngle = 1.0,
    this.rain = false,
  });

  factory SensorHistoryPoint.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      ts = json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'].toString())
          : DateTime.now();
    } catch (_) {
      ts = DateTime.now();
    }

    return SensorHistoryPoint(
      timestamp: ts,
      leakageCurrent: (json['leakage_current'] as num?)?.toDouble() ?? 0.0,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 230.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 28.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 50.0,
      tiltAngle: (json['tilt_angle'] as num?)?.toDouble() ?? 1.0,
      rain: json['rain'] as bool? ?? false,
    );
  }

  double getValueForMetric(String metricKey) {
    switch (metricKey) {
      case 'leakage':
        return leakageCurrent;
      case 'voltage':
        return voltage;
      case 'temp':
        return temperature;
      case 'humidity':
        return humidity;
      case 'tilt':
        return tiltAngle;
      default:
        return leakageCurrent;
    }
  }
}
