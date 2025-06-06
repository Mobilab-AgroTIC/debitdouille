import 'package:flutter/material.dart';

class DataFrameOverlay extends StatelessWidget {
  final String lastJsonFrame;

  const DataFrameOverlay({Key? key, required this.lastJsonFrame}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.black.withOpacity(0.7),
      child: Text(
        lastJsonFrame,
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}
