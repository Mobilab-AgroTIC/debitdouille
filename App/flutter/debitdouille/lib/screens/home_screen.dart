import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/value_block.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final dp = context.watch<DataProvider>();
    final d = dp.data;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pression (au-dessus des débits) — facteur local 1.0 (tu peux mettre 1.2 si tu veux plus gros)
            ValueBlock(
              label: "Pression",
              value: d.P.toStringAsFixed(settings.decimalsPressure),
              unit: "bar",
              fontScale: 1.0,
            ),
            const SizedBox(height: 20),

            // Débits gauche / droite
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _debitsColumn("DG", dp, settings.pairs, 1.0, settings.decimalsFlow)),
                const SizedBox(width: 16),
                Expanded(child: _debitsColumn("DD", dp, settings.pairs, 1.0, settings.decimalsFlow)),
              ],
            ),

            const SizedBox(height: 20),

            // Vitesse (juste en dessous des débits)
            ValueBlock(
              label: "Vitesse",
              value: d.V.toStringAsFixed(settings.decimalsSpeed),
              unit: "km/h",
              fontScale: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _debitsColumn(String prefix, DataProvider dp, int pairs, double localScale, int decimals) {
    final items = List.generate(pairs, (i) {
      final key = "$prefix${i + 1}";
      final source = dp.flowMeterConfig.getSource(key);
      final v = dp.data.getValue(key, source);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ValueBlock(
          label: "$key (L/min)",
          value: v.toStringAsFixed(decimals),
          unit: "",
          fontScale: localScale,
        ),
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: items,
    );
  }
}
