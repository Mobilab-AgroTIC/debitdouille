import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../widgets/status_dot.dart';
import '../screens/home_screen.dart';
import '../screens/bluetooth_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calibration_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final dataProv = context.watch<DataProvider>();

    Widget body;
    switch (settings.page) {
      case AppPage.home:
        body = const HomeScreen();
        break;
      case AppPage.bluetooth:
        body = const BluetoothScreen();
        break;
      case AppPage.calibration:
        body = const CalibrationScreen();
        break;
      case AppPage.settings:
        body = const SettingsScreen();
        break;
    }

    return PopScope(
      // Autoriser le "pop" (fermeture de l'app) uniquement quand on est sur Home
      canPop: settings.page == AppPage.home,
      onPopInvoked: (didPop) {
        // Si un pop a déjà été effectué par le framework, on ne fait rien.
        if (didPop) return;
        // Sinon, on consomme l’événement et on revient à Home.
        if (settings.page != AppPage.home) {
          settings.go(AppPage.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            children: [
              const Text("", style: TextStyle(color: Colors.white)),
              const SizedBox(width: 12),
              StatusDot(alive: dataProv.isAlive),
              const SizedBox(width: 8),
              Text(
                dataProv.connectedDevice != null
                    ? "Connecté à : ${dataProv.connectedDevice!.platformName}"
                    : "Non connecté",
                style: const TextStyle(color: AppColors.dim, fontSize: 14),
              ),
            ],
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                tooltip: "Paramètres / Pages",
              ),
            ),
          ],
        ),
        endDrawer: const _EndDrawer(),
        body: body,
        floatingActionButton: settings.showSimButton
            ? FloatingActionButton(
                backgroundColor: Colors.white10,
                onPressed: () => dataProv.pushSimulatedFrame(settings.pairs),
                child: const Icon(Icons.bug_report, color: Colors.white),
              )
            : null,
        bottomNavigationBar: settings.showDebug
            ? Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: Text(
                  dataProv.lastJson ?? "{}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: "monospace",
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _EndDrawer extends StatelessWidget {
  const _EndDrawer();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text("Menu", style: TextStyle(color: Colors.white70)),
),
            _nav(context, "🏠 Accueil", AppPage.home, settings),
            _nav(context, "🔗 Connexion Bluetooth", AppPage.bluetooth, settings),
            _nav(context, "⚖️ Calibration des capteurs", AppPage.calibration, settings),
            const Divider(color: Colors.white24),
            _nav(context, "⚙️ Paramètres", AppPage.settings, settings),
          ],
        ),
      ),
    );
  }

  Widget _nav(BuildContext ctx, String label, AppPage target, SettingsProvider s) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(ctx).pop(); // fermer le drawer
        s.go(target);
      },
    );
  }
}