import 'package:flutter/material.dart';

class CalibrationPage extends StatelessWidget {
  const CalibrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibrer les capteurs')),
      body: const Center(
        child: Text('Page de calibration à implémenter'),
      ),
    );
  }
}
