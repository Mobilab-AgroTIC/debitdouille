import 'package:flutter/material.dart';

class StatusDot extends StatefulWidget {
  final bool alive;
  final bool isReconnecting;
  final bool hasPacketLoss;
  const StatusDot({
    super.key,
    required this.alive,
    this.isReconnecting = false,
    this.hasPacketLoss = false,
  });

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Structure constante : toujours un AnimatedBuilder pour éviter les changements de widget tree
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Color color;

        if (widget.isReconnecting) {
          // 🟠 Orange clignotant pour la reconnexion
          color = Colors.orange.withOpacity(0.3 + (_controller.value * 0.7));
        } else if (widget.hasPacketLoss) {
          // 🟠🟢 Orange/Vert alternant pour perte de paquets
          color = _controller.value < 0.5 ? Colors.orange : Colors.greenAccent;
        } else {
          // 🟢🔴 Vert ou rouge selon l'état alive (normal, sans animation)
          color = widget.alive ? Colors.greenAccent : Colors.redAccent;
        }

        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
