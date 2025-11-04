import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  final bool alive;
  const StatusDot({super.key, required this.alive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: alive ? Colors.greenAccent : Colors.redAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}
