import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ou riverpod, selon votre choix

import 'providers/bluetooth_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/connection_screen.dart';
import 'screens/calibration_screen.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadInitial()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProxyProvider<BluetoothProvider, SensorProvider>(
          create: (_) => SensorProvider(),
          update: (_, bluetoothProv, sensorProv) {
            sensorProv!..setBluetoothProvider(bluetoothProv);
            return sensorProv;
          },
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Débitdouille',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/connection',
      routes: {
        '/connection': (_) => ConnectionScreen(),
        '/calibration': (_) => CalibrationScreen(),
        '/main': (_) => MainScreen(),
        '/settings': (_) => SettingsScreen(),
      },
    );
  }
}
