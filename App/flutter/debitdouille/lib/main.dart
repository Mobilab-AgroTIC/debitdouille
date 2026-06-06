import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'utils/constants.dart';
import 'services/ble_service.dart';
import 'services/simulation_service.dart';
import 'services/flow_meter_config_service.dart';
import 'providers/data_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/app_shell.dart';
import 'utils/app_version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charge la version depuis le pubspec (affichée dans l'écran Paramètres).
  await AppVersion.init();

  WakelockPlus.enable();

  final settings = SettingsProvider();
  await settings.load();

  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        Provider<BleService>(create: (_) => BleService()),
        Provider<SimulationService>(create: (_) => SimulationService()),
        Provider<FlowMeterConfigService>(create: (_) => FlowMeterConfigService()),
        ChangeNotifierProvider<DataProvider>(
          create: (ctx) => DataProvider(
            ble: ctx.read<BleService>(),
            sim: ctx.read<SimulationService>(),
            flowMeterConfigService: ctx.read<FlowMeterConfigService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Débitdouille",
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.background,
          textTheme: ThemeData.dark().textTheme.apply(
                bodyColor: AppColors.text,
                displayColor: AppColors.text,
              ),
        ),
        home: const AppShell(),
      ),
    );
  }
}
