import 'package:flutter/material.dart';

class SensorValueWidget extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const SensorValueWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        RichText(
          text: TextSpan(
            text: value.toStringAsFixed(2),
            style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
