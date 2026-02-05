import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onClearPressed;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map((number) => _buildKey(number, () => onNumberPressed(number)))
                .toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('C', onClearPressed, color: Colors.orange[100]),
            _buildKey('0', () => onNumberPressed('0')),
            _buildKey('⌫', onDeletePressed, color: Colors.red[100]),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String text, VoidCallback onPressed, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: 60,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
