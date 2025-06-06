import 'package:flutter/material.dart';

class SimulateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SimulateButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.white,
      child: Icon(Icons.play_arrow, color: Colors.black),
    );
  }
}
