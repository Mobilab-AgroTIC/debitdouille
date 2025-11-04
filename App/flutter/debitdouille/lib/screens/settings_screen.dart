import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/value_block.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    const titleStyle = TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold);
    const sectionLabelStyle = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500);
    const smallLabelStyle = TextStyle(color: Colors.white54, fontSize: 16);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("Paramètres d'affichage", style: titleStyle),
          const SizedBox(height: 16),

          // ---- Paires de débits ----
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Paires de débits :", style: sectionLabelStyle),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final value = i + 1;
                  final isSelected = s.pairs == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.white : Colors.transparent,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => s.setPairs(value),
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),

          // ---- Taille du texte ----
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Taille du texte", style: sectionLabelStyle),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Petit", style: smallLabelStyle),
                  Expanded(
                    child: Slider(
                      value: s.fontScale,
                      min: 0.6,
                      max: 2.0,
                      divisions: 6,
                      label: "${(s.fontScale * 100).round()}%",
                      onChanged: (v) => s.setFontScale(v),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                    ),
                  ),
                  const Text("Grand", style: smallLabelStyle),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ Aperçu fiable : réutilise le même composant que la Home
              Center(
                child: ValueBlock(
                  label: "Aperçu",
                  value: "12.34",
                  unit: "bar",
                  fontScale: 1.0, // facteur local: 1.0
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),

          // ---- Debug / Simulation ----
          SwitchListTile(
            value: s.showDebug,
            onChanged: (v) => s.setShowDebug(v),
            title: const Text("Afficher trame JSON (debug)", style: sectionLabelStyle),
            activeColor: Colors.white,
          ),
          SwitchListTile(
            value: s.showSimButton,
            onChanged: (v) => s.setShowSimButton(v),
            title: const Text("Afficher bouton Simulation", style: sectionLabelStyle),
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
