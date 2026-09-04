import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final RiskTier tier;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.tier,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.icon,
            size: isCompact ? 14 : 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            tier.label,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
