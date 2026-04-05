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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Planifier l'initialisation après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProv = context.read<DataProvider>();
      dataProv.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

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
        // Sinon, on consomme l'événement et on revient à Home.
        if (settings.page != AppPage.home) {
          settings.go(AppPage.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: _buildAppBarTitle(),
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
        floatingActionButton: _buildFloatingActionButton(settings),
        bottomNavigationBar: _buildDebugBar(settings),
      ),
    );
  }

  // 🎯 Widget séparé qui écoute uniquement les propriétés nécessaires pour l'AppBar
  Widget _buildAppBarTitle() {
    return Selector<DataProvider, _AppBarState>(
      selector: (_, dp) => _AppBarState(
        isAlive: dp.isAlive,
        isReconnecting: dp.isReconnecting,
        hasPacketLoss: dp.hasPacketLoss,
        connectedName: dp.connectedDeviceName,
        isConnected: dp.connectedDevice != null,
      ),
      builder: (_, state, __) {
        return Row(
          children: [
            const Text("", style: TextStyle(color: Colors.white)),
            const SizedBox(width: 12),
            StatusDot(
              alive: state.isAlive,
              isReconnecting: state.isReconnecting,
              hasPacketLoss: state.hasPacketLoss,
            ),
            const SizedBox(width: 8),
            Text(
              state.isReconnecting
                  ? "Reconnexion en cours..."
                  : state.hasPacketLoss
                      ? "Connexion instable"
                      : state.isConnected
                          ? "Connecté à : ${state.connectedName ?? 'Appareil inconnu'}"
                          : "Non connecté",
              style: const TextStyle(color: AppColors.dim, fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  // 🎯 FloatingActionButton isolé
  Widget? _buildFloatingActionButton(SettingsProvider settings) {
    if (!settings.showSimButton) return null;

    return Selector<DataProvider, VoidCallback>(
      selector: (_, dp) => () => dp.pushSimulatedFrame(settings.pairs),
      builder: (_, onPressed, __) {
        return FloatingActionButton(
          backgroundColor: Colors.white10,
          onPressed: onPressed,
          child: const Icon(Icons.bug_report, color: Colors.white),
        );
      },
    );
  }

  // 🎯 Barre de debug isolée
  Widget? _buildDebugBar(SettingsProvider settings) {
    if (!settings.showDebug) return null;

    return Selector<DataProvider, String?>(
      selector: (_, dp) => dp.lastJson,
      builder: (_, lastJson, __) {
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black,
          child: Text(
            lastJson ?? "{}",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: "monospace",
            ),
          ),
        );
      },
    );
  }
}

// 📦 Classe immutable pour l'état de l'AppBar
class _AppBarState {
  final bool isAlive;
  final bool isReconnecting;
  final bool hasPacketLoss;
  final String? connectedName;
  final bool isConnected;

  _AppBarState({
    required this.isAlive,
    required this.isReconnecting,
    required this.hasPacketLoss,
    required this.connectedName,
    required this.isConnected,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AppBarState &&
          isAlive == other.isAlive &&
          isReconnecting == other.isReconnecting &&
          hasPacketLoss == other.hasPacketLoss &&
          connectedName == other.connectedName &&
          isConnected == other.isConnected;

  @override
  int get hashCode =>
      isAlive.hashCode ^
      isReconnecting.hashCode ^
      hasPacketLoss.hashCode ^
      connectedName.hashCode ^
      isConnected.hashCode;
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