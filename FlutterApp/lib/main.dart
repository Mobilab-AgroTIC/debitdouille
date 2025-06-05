import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/connection_page.dart';
import 'pages/calibration_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const DebitdouilleApp());
}

class DebitdouilleApp extends StatelessWidget {
  const DebitdouilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Débitdouille',
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => const HomePage(),
        '/connect': (context) => const ConnectionPage(),
        '/calibrate': (context) => const CalibrationPage(),
        '/settings': (context) => const SettingsPage(),
      },
      initialRoute: '/',
    );
  }
}
