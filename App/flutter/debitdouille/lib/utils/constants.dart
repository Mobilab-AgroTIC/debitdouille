import 'package:flutter/material.dart';

class AppColors {
  static const background = Colors.black;
  static const text = Colors.white;
  static const dim = Colors.white70;
}

class BleUUID {
  static const service = "0000ffe1-0000-1000-8000-00805f9b34fb";
  static const notifyChar = "0000ffe1-0000-1000-8000-00805f9b34fb";
  static const writeChar  = "0000ffe1-0000-1000-8000-00805f9b34fb";
}

const tickDuration = Duration(seconds: 3); // seuil point vert/rouge
