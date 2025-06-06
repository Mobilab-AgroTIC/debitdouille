import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

enum ConnectionStatus { connected, none, error }

class StatusIndicator extends StatefulWidget {
  final ConnectionStatus status;

  const StatusIndicator({Key? key, required this.status}) : super(key: key);

  @override
  _StatusIndicatorState createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
      lowerBound: 0.2,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    bool animate;
    switch (widget.status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        animate = true;
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        animate = false;
        break;
      default:
        color = Colors.grey;
        animate = true;
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: animate
          ? FadeTransition(
              opacity: _controller,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
