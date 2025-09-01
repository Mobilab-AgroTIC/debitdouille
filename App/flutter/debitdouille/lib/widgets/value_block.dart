import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class ValueBlock extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  /// Facteur local optionnel (pression 1.2, vitesse 1.0, etc.)
  /// L’échelle effective = (fontScale global depuis Settings) * (fontScale local).
  final double fontScale;

  const ValueBlock({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Échelle globale provenant des réglages
    final global = context.watch<SettingsProvider>().fontScale;
    // Échelle effective
    final s = (global * fontScale).clamp(0.4, 3.0);

    const double baseValue = 48;
    const double baseLabel = 16;
    const double baseUnit  = 16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.dim,
            fontSize: baseLabel * (0.90 * s),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.text,
                fontSize: baseValue * s,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: AppColors.dim,
                    fontSize: baseUnit * (0.95 * s),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
