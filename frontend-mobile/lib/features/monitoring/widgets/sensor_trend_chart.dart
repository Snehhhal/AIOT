import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/theme/app_theme.dart';
import '../../../models/sensor_history_model.dart';

class SensorTrendChart extends StatefulWidget {
  final List<SensorHistoryPoint> points;
  final String initialMetric;
  final bool showControls;

  const SensorTrendChart({
    super.key,
    required this.points,
    this.initialMetric = 'leakage',
    this.showControls = true,
  });

  @override
  State<SensorTrendChart> createState() => _SensorTrendChartState();
}

class _SensorTrendChartState extends State<SensorTrendChart> {
  late String _activeMetric;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _activeMetric = widget.initialMetric;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: const Text(
          'No historical telemetry data available.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    final metricConfig = _getMetricConfig(_activeMetric);
    final values = widget.points.map((p) => p.getValueForMetric(_activeMetric)).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final avgVal = values.reduce((a, b) => a + b) / values.length;
    final currentVal = values.last;
    final breaches = metricConfig.dangerThreshold != null
        ? values.where((v) => v >= metricConfig.dangerThreshold!).length
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Selector Chips
          if (widget.showControls)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricChip('leakage', 'Leakage Current (mA)', Icons.flash_on_rounded),
                  const SizedBox(width: 8),
                  _buildMetricChip('voltage', 'Touch Voltage (V)', Icons.bolt_rounded),
                  const SizedBox(width: 8),
                  _buildMetricChip('temp', 'Temperature (°C)', Icons.thermostat_rounded),
                  const SizedBox(width: 8),
                  _buildMetricChip('humidity', 'Humidity (%)', Icons.water_drop_rounded),
                  const SizedBox(width: 8),
                  _buildMetricChip('tilt', 'Tilt Angle (°)', Icons.screen_rotation_rounded),
                ],
              ),
            ),
          if (widget.showControls) const SizedBox(height: 14),

          // Chart Header & Current Value Readout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metricConfig.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '24-Hour Sequential Telemetry Trend',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: metricConfig.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: metricConfig.accentColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${currentVal.toStringAsFixed(1)} ${metricConfig.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: metricConfig.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Interactive Canvas Chart
          SizedBox(
            height: 160,
            width: double.infinity,
            child: GestureDetector(
              onPanUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final local = details.localPosition;
                  final index = (local.dx / box.size.width * widget.points.length)
                      .clamp(0, widget.points.length - 1)
                      .toInt();
                  setState(() => _selectedIndex = index);
                }
              },
              onPanEnd: (_) => setState(() => _selectedIndex = null),
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final local = details.localPosition;
                  final index = (local.dx / box.size.width * widget.points.length)
                      .clamp(0, widget.points.length - 1)
                      .toInt();
                  setState(() => _selectedIndex = index);
                }
              },
              child: CustomPaint(
                painter: _TrendChartPainter(
                  points: widget.points,
                  metricKey: _activeMetric,
                  accentColor: metricConfig.accentColor,
                  dangerThreshold: metricConfig.dangerThreshold,
                  dangerLabel: metricConfig.dangerLabel,
                  selectedIndex: _selectedIndex,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Touch Inspection Card (When scrubbing)
          if (_selectedIndex != null && _selectedIndex! < widget.points.length)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: metricConfig.accentColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, HH:mm').format(widget.points[_selectedIndex!].timestamp),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.points[_selectedIndex!].getValueForMetric(_activeMetric).toStringAsFixed(1)} ${metricConfig.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: metricConfig.accentColor,
                    ),
                  ),
                ],
              ),
            ),

          // Statistics Aggregate Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Min', '${minVal.toStringAsFixed(1)} ${metricConfig.unit}'),
                _buildStatItem('Avg', '${avgVal.toStringAsFixed(1)} ${metricConfig.unit}'),
                _buildStatItem('Max', '${maxVal.toStringAsFixed(1)} ${metricConfig.unit}'),
                if (metricConfig.dangerThreshold != null)
                  _buildStatItem(
                    'Breaches',
                    breaches.toString(),
                    color: breaches > 0 ? AppTheme.emergencyColor : AppTheme.safeColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String key, String title, IconData icon) {
    final isSelected = _activeMetric == key;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textSecondary),
      label: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.infoColor,
      backgroundColor: AppTheme.cardDark,
      side: BorderSide(
        color: isSelected ? AppTheme.infoColor : AppTheme.borderDark,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _activeMetric = key);
      },
    );
  }

  static Widget _buildStatItem(String label, String value, {Color color = AppTheme.textPrimary}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  static _MetricConfig _getMetricConfig(String key) {
    switch (key) {
      case 'leakage':
        return _MetricConfig(
          label: 'Leakage Current Trend',
          unit: 'mA',
          accentColor: AppTheme.emergencyColor,
          dangerThreshold: 30.0,
          dangerLabel: '30mA Let-Go Limit (IEC 60479)',
        );
      case 'voltage':
        return _MetricConfig(
          label: 'Surface Touch Voltage',
          unit: 'V',
          accentColor: AppTheme.dangerColor,
          dangerThreshold: 50.0,
          dangerLabel: '50V Touch Potential Hazard',
        );
      case 'temp':
        return _MetricConfig(
          label: 'Operating Temperature',
          unit: '°C',
          accentColor: AppTheme.warningColor,
          dangerThreshold: 55.0,
          dangerLabel: '55°C Thermal Overload Warning',
        );
      case 'humidity':
        return _MetricConfig(
          label: 'Ambient Humidity',
          unit: '%',
          accentColor: AppTheme.infoColor,
        );
      case 'tilt':
        return _MetricConfig(
          label: 'Pole Tilt Inclination',
          unit: '°',
          accentColor: const Color(0xFFA855F7),
          dangerThreshold: 15.0,
          dangerLabel: '15° Structural Collapse Warning',
        );
      default:
        return _MetricConfig(
          label: 'Sensor Metric',
          unit: '',
          accentColor: AppTheme.infoColor,
        );
    }
  }
}

class _MetricConfig {
  final String label;
  final String unit;
  final Color accentColor;
  final double? dangerThreshold;
  final String? dangerLabel;

  _MetricConfig({
    required this.label,
    required this.unit,
    required this.accentColor,
    this.dangerThreshold,
    this.dangerLabel,
  });
}

class _TrendChartPainter extends CustomPainter {
  final List<SensorHistoryPoint> points;
  final String metricKey;
  final Color accentColor;
  final double? dangerThreshold;
  final String? dangerLabel;
  final int? selectedIndex;

  _TrendChartPainter({
    required this.points,
    required this.metricKey,
    required this.accentColor,
    this.dangerThreshold,
    this.dangerLabel,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points.map((p) => p.getValueForMetric(metricKey)).toList();
    double minVal = values.reduce(min);
    double maxVal = values.reduce(max);

    if (dangerThreshold != null) {
      maxVal = max(maxVal, dangerThreshold! * 1.15);
      minVal = min(minVal, 0.0);
    }
    if (maxVal == minVal) {
      maxVal += 10.0;
      minVal = max(0.0, minVal - 10.0);
    }

    final double range = maxVal - minVal;
    final double stepX = size.width / (points.length - 1);

    // 1. Draw Grid Lines (Horizontal)
    final gridPaint = Paint()
      ..color = AppTheme.borderDark.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Danger Threshold Reference Line
    if (dangerThreshold != null && dangerThreshold! >= minVal && dangerThreshold! <= maxVal) {
      final thresholdY = size.height - ((dangerThreshold! - minVal) / range * size.height);
      final thresholdPaint = Paint()
        ..color = AppTheme.emergencyColor.withValues(alpha: 0.8)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, thresholdY),
          Offset(min(startX + dashWidth, size.width), thresholdY),
          thresholdPaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Draw Label
      if (dangerLabel != null) {
        final textSpan = TextSpan(
          text: dangerLabel!,
          style: const TextStyle(
            color: AppTheme.emergencyColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(8, max(2.0, thresholdY - 14)));
      }
    }

    // 3. Build Smooth Path & Gradient
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final val = values[i];
      final x = i * stepX;
      final y = size.height - ((val - minVal) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - ((values[i - 1] - minVal) / range * size.height);
        final midX = (prevX + x) / 2.0;
        path.cubicTo(midX, prevY, midX, y, x, y);
        fillPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 4. Paint Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.35),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Paint Line Stroke
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // 6. Draw Data Points / Breaches
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final haloPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final val = values[i];
      final x = i * stepX;
      final y = size.height - ((val - minVal) / range * size.height);
      final isBreach = dangerThreshold != null && val >= dangerThreshold!;

      if (isBreach) {
        haloPaint.color = AppTheme.emergencyColor.withValues(alpha: 0.3);
        canvas.drawCircle(Offset(x, y), 6, haloPaint);
        dotPaint.color = AppTheme.emergencyColor;
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      } else if (i == points.length - 1) {
        dotPaint.color = accentColor;
        canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      }
    }

    // 7. Draw Scrubber Indicator
    if (selectedIndex != null && selectedIndex! < points.length) {
      final scrubX = selectedIndex! * stepX;
      final scrubY = size.height - ((values[selectedIndex!] - minVal) / range * size.height);

      final scrubPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.0;

      canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, size.height), scrubPaint);

      final activeDotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(scrubX, scrubY), 5, activeDotPaint);
      canvas.drawCircle(Offset(scrubX, scrubY), 3, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.metricKey != metricKey ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
